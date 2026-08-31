#!/bin/bash
# Collect usage limits for the three AI subscriptions and print one
# normalized JSON document on stdout:
#
#   { "updatedAt": ISO, "providers": [
#       { id, name, plan, ok, stale, error, limits: [{label, percent, resetsAt}] } ] }
#
# percent is 0-100 or null (unknown), resetsAt is ISO 8601 or null.
#
# Sources (all credentials are read-only here; each CLI refreshes its own file):
#   claude   GET api.anthropic.com/api/oauth/usage with the Claude Code OAuth
#            token from ~/.claude/.credentials.json (skipped when expired —
#            refreshing it is the claude binary's job)
#   opencode GET opencode.ai/zen/go/v1/usage with the opencode-go API key
#   codex    `codex app-server` JSON-RPC account/rateLimits/read, so the codex
#            binary handles its own token refresh
#
# The last good payload per provider is cached in ~/.cache/ai-usage/ and served
# with stale=true when a probe fails, so the widget never blanks.

set -u

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ai-usage"
mkdir -p "$CACHE"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Serve the cached copy marked stale, or an error-only stub.
fallback() { # id name error-message
    if [ -f "$CACHE/$1.json" ]; then
        jq --arg e "$3" '.stale = true | .error = $e' "$CACHE/$1.json"
    else
        jq -n --arg id "$1" --arg n "$2" --arg e "$3" \
            '{id: $id, name: $n, plan: null, ok: false, stale: false, error: $e, limits: []}'
    fi
}

probe_claude() {
    local out="$TMP/claude.json" creds="$HOME/.claude/.credentials.json"
    [ -f "$creds" ] || { fallback claude Claude "no credentials file" > "$out"; return; }

    local token expires tier plan resp
    token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds")
    expires=$(jq -r '.claudeAiOauth.expiresAt // 0' "$creds")
    tier=$(jq -r '.claudeAiOauth.rateLimitTier // ""' "$creds")
    case "$tier" in
        *_5x*)  plan="Max 5x" ;;
        *_20x*) plan="Max 20x" ;;
        *)      plan=$(jq -r '.claudeAiOauth.subscriptionType // "?"' "$creds") ;;
    esac
    [ -n "$token" ] || { fallback claude Claude "no OAuth token" > "$out"; return; }
    if [ "$(date +%s%3N)" -ge "$expires" ]; then
        fallback claude Claude "token expired — run claude" > "$out"
        return
    fi

    # The beta header is mandatory; a browser-less User-Agent avoids the
    # aggressively rate-limited anonymous bucket (persistent 429s without it).
    resp=$(curl -sf --max-time 10 \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "User-Agent: claude-code/2.1.252 (external, cli)" \
        https://api.anthropic.com/api/oauth/usage) \
        || { fallback claude Claude "usage request failed" > "$out"; return; }

    # utilization is 0-1 in some payloads and 0-100 in others: if any raw
    # value reaches 1 treat the whole payload as 0-100. Model-scoped windows
    # (e.g. a Fable weekly cap) only appear in the top-level limits[] array.
    jq --arg plan "$plan" '
        ([.five_hour.utilization?, .seven_day.utilization?,
          .seven_day_oauth_apps.utilization?, (.limits[]?.percent?)]
         | map(select(type == "number"))) as $vals
        | (if ($vals | any(. >= 1)) then 1 else 100 end) as $m
        | {id: "claude", name: "Claude", plan: $plan, ok: true, stale: false, error: null,
           limits: ([
             (.five_hour | select(. != null and .utilization != null)
              | {label: "Session", percent: (.utilization * $m), resetsAt: .resets_at}),
             ((.seven_day_oauth_apps // .seven_day) | select(. != null and .utilization != null)
              | {label: "Weekly", percent: (.utilization * $m), resetsAt: .resets_at}),
             (.limits[]? | select(.scope?.model?.display_name? != null and .percent != null)
              | {label: (.scope.model.display_name
                         + (if (.kind // "" | test("five_hour")) then " 5h" else " weekly" end)),
                 percent: (.percent * $m), resetsAt: .resets_at})
           ])}' <<< "$resp" > "$out" 2>/dev/null \
        && cp "$out" "$CACHE/claude.json" \
        || fallback claude Claude "unexpected response shape" > "$out"
}

probe_opencode() {
    local out="$TMP/opencode.json" auth="$HOME/.local/share/opencode/auth.json"
    local name="OpenCode Go" key resp
    key=$(jq -r '.["opencode-go"].key // empty' "$auth" 2>/dev/null)
    [ -n "$key" ] || { fallback opencode "$name" "no opencode-go key in auth.json" > "$out"; return; }

    resp=$(curl -sf --max-time 10 \
        -H "Authorization: Bearer $key" \
        -H "User-Agent: ai-usage/1.0" \
        https://opencode.ai/zen/go/v1/usage) \
        || { fallback opencode "$name" "usage request failed" > "$out"; return; }

    # Windows: rolling (5h) / weekly / monthly; a non-"ok" status means the
    # percent is unreliable, so report the window with percent null.
    jq '.usage
        | {id: "opencode", name: "OpenCode Go", plan: "Go", ok: true, stale: false, error: null,
           limits: ([{label: "5h", w: .rolling}, {label: "Weekly", w: .weekly},
                     {label: "Monthly", w: .monthly}]
             | map(select(.w != null)
               | {label: .label,
                  percent: (if (.w.status // "ok") == "ok" then .w.percent else null end),
                  resetsAt: (.w.resetsAt // null)}))}' <<< "$resp" > "$out" 2>/dev/null \
        && cp "$out" "$CACHE/opencode.json" \
        || fallback opencode "$name" "unexpected response shape" > "$out"
}

probe_codex() {
    local out="$TMP/codex.json" rpc
    command -v codex >/dev/null || { fallback codex Codex "codex CLI not installed" > "$out"; return; }

    # app-server speaks JSON-RPC on stdio; read until the rateLimits response
    # arrives, then kill it. The codex binary refreshes its own tokens.
    rpc=$(timeout 20 python3 - <<'PY' 2>/dev/null
import json, subprocess, sys
p = subprocess.Popen(
    ["codex", "-s", "read-only", "-a", "never", "app-server"],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL, text=True)
def send(o):
    p.stdin.write(json.dumps(o) + "\n")
    p.stdin.flush()
send({"jsonrpc": "2.0", "id": 1, "method": "initialize",
      "params": {"clientInfo": {"name": "ai-usage", "version": "1.0"}}})
send({"jsonrpc": "2.0", "method": "initialized"})
send({"jsonrpc": "2.0", "id": 2, "method": "account/rateLimits/read", "params": {}})
for line in p.stdout:
    try:
        msg = json.loads(line)
    except ValueError:
        continue
    if msg.get("id") == 2:
        print(json.dumps(msg))
        break
p.kill()
PY
    )
    [ -n "$rpc" ] || { fallback codex Codex "app-server did not answer" > "$out"; return; }

    # Windows carry usedPercent / windowDurationMins / resetsAt (unix seconds).
    jq '.result.rateLimits as $rl
        | if $rl == null then error("no rateLimits") else . end
        | {id: "codex", name: "Codex", plan: ($rl.planType // null), ok: true, stale: false, error: null,
           limits: ([$rl.primary, $rl.secondary]
             | map(select(. != null)
               | {label: (if .windowDurationMins == null then "Window"
                          elif .windowDurationMins == 10080 then "Weekly"
                          elif .windowDurationMins == 43200 then "Monthly"
                          elif .windowDurationMins >= 1440 then "\(.windowDurationMins / 1440 | floor)d"
                          else "\(.windowDurationMins / 60 | floor)h" end),
                  percent: (.usedPercent // null),
                  resetsAt: (if .resetsAt == null then null else (.resetsAt | todate) end)}))}' \
        <<< "$rpc" > "$out" 2>/dev/null \
        && cp "$out" "$CACHE/codex.json" \
        || fallback codex Codex "unexpected response shape" > "$out"
}

probe_claude &
probe_opencode &
probe_codex &
wait

jq -n --arg t "$(date -u +%FT%TZ)" \
    '{updatedAt: $t, providers: [inputs]}' \
    "$TMP/claude.json" "$TMP/opencode.json" "$TMP/codex.json"
