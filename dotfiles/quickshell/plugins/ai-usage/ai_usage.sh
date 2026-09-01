#!/bin/bash
# Collect usage limits for the AI subscriptions and print one
# normalized JSON document on stdout:
#
#   { "updatedAt": ISO, "providers": [
#       { id, name, plan, ok, stale, error, limits: [{label, percent, resetsAt}] } ] }
#
# percent is 0-100 or null (unknown), resetsAt is ISO 8601 or null.
#
# Sources (all credentials are read-only here; each CLI refreshes its own file):
#   claude       GET api.anthropic.com/api/oauth/usage with the Claude Code OAuth
#                token from ~/.claude/.credentials.json (skipped when expired —
#                refreshing it is the claude binary's job)
#   opencode     GET opencode.ai/zen/go/v1/usage with the opencode-go API key
#   codex        `codex app-server` JSON-RPC account/rateLimits/read, so the codex
#                binary handles its own token refresh
#   antigravity  GET/POST daily-cloudcode-pa.googleapis.com/v1internal:fetchAvailableModels
#                with OAuth token from Secret Service / ~/.gemini/
#
# The last good payload per provider is cached in ~/.cache/ai-usage/ and served
# with stale=true when a probe fails, so the widget never blanks.

set -u

# Ensure user bin directories are on PATH for subprocesses
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/pnpm:$PATH"
if [ -d "$HOME/.nvm/versions/node" ]; then
    NODE_BIN=$(find "$HOME/.nvm/versions/node" -maxdepth 2 -type d -name "bin" 2>/dev/null | sort -V | tail -n 1)
    [ -n "$NODE_BIN" ] && export PATH="$NODE_BIN:$PATH"
fi

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

probe_agy() {
    local out="$TMP/agy.json" payload
    command -v agy >/dev/null || [ -d "$HOME/.gemini" ] || { fallback agy Antigravity "agy not installed" > "$out"; return; }

    payload=$(timeout 15 python3 - <<'PY' 2>/dev/null
import json, os, urllib.request, urllib.parse

def get_keyring_token():
    try:
        import secretstorage
        bus = secretstorage.dbus_init()
        for col in secretstorage.get_all_collections(bus):
            for item in col.get_all_items():
                attrs = item.get_attributes()
                if attrs.get('service') == 'gemini' and attrs.get('username') == 'antigravity':
                    sec = json.loads(item.get_secret().decode('utf-8'))
                    return sec.get('token', {})
    except Exception:
        pass
    return {}

def refresh_access_token(rtoken):
    # gemini-cli's installed-app OAuth client. Kept out of the repo (GitHub
    # push protection flags it); copy it from any gemini-cli install into
    # ~/.config/ai-usage/google-oauth.json: {"client_id": ..., "client_secret": ...}
    cfg = os.path.join(os.environ.get('XDG_CONFIG_HOME', os.path.expanduser('~/.config')), 'ai-usage', 'google-oauth.json')
    with open(cfg) as f:
        oc = json.load(f)
    cid = oc['client_id']
    csec = oc['client_secret']
    data = urllib.parse.urlencode({
        'client_id': cid,
        'client_secret': csec,
        'refresh_token': rtoken,
        'grant_type': 'refresh_token'
    }).encode('utf-8')
    req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
    with urllib.request.urlopen(req, timeout=10) as resp:
        res = json.loads(resp.read().decode('utf-8'))
        return res.get('access_token')

def fetch_api(ep, tok):
    req = urllib.request.Request(
        f'https://daily-cloudcode-pa.googleapis.com/v1internal:{ep}',
        data=b'{}',
        headers={
            'Authorization': f'Bearer {tok}',
            'Content-Type': 'application/json',
            'User-Agent': 'antigravity-cli'
        }
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode('utf-8'))

tok_data = get_keyring_token()
token = tok_data.get('access_token')
refresh_token = tok_data.get('refresh_token')

if not token and not refresh_token:
    try:
        p = os.path.expanduser('~/.gemini/oauth_creds.json')
        if os.path.exists(p):
            with open(p) as f:
                c = json.load(f)
                token = c.get('access_token')
                refresh_token = c.get('refresh_token') or refresh_token
    except Exception:
        pass

if not token and not refresh_token:
    print(json.dumps({"error": "no credentials found"}))
    exit(0)

models_data = None
try:
    models_data = fetch_api('fetchAvailableModels', token)
except Exception as e:
    if refresh_token:
        try:
            token = refresh_access_token(refresh_token)
            if token:
                models_data = fetch_api('fetchAvailableModels', token)
        except Exception as e2:
            print(json.dumps({"error": f"token refresh failed: {e2}"}))
            exit(0)
    if not models_data:
        print(json.dumps({"error": f"fetch models failed: {e}"}))
        exit(0)

plan = "Free"
try:
    ca = fetch_api('loadCodeAssist', token)
    tier_id = ca.get('currentTier', {}).get('id', '')
    if 'pro' in tier_id.lower():
        plan = "Pro"
    elif tier_id == 'free-tier':
        plan = "Free"
    elif ca.get('currentTier', {}).get('name'):
        plan = ca['currentTier']['name']
except Exception:
    pass

models = models_data.get('models', {})
buckets = {}
for name, m in models.items():
    if not m.get('displayName'):
        continue
    qi = m.get('quotaInfo')
    if not qi:
        continue
    provider = m.get('modelProvider')
    if provider == 'MODEL_PROVIDER_GOOGLE':
        group = 'Gemini'
    elif provider in ('MODEL_PROVIDER_ANTHROPIC', 'MODEL_PROVIDER_OPENAI'):
        group = 'Claude & GPT'
    else:
        group = provider.replace('MODEL_PROVIDER_', '').title()
    if group not in buckets:
        buckets[group] = qi

limits = []
order = ['Gemini', 'Claude & GPT']
for grp in order + [k for k in buckets if k not in order]:
    if grp in buckets:
        qi = buckets[grp]
        rem = qi.get('remainingFraction')
        pct = max(0, min(100, round((1.0 - rem) * 100, 1))) if rem is not None else None
        limits.append({
            "label": grp,
            "percent": pct,
            "resetsAt": qi.get('resetTime')
        })

print(json.dumps({
    "id": "agy",
    "name": "Antigravity",
    "plan": plan,
    "ok": True,
    "stale": False,
    "error": None,
    "limits": limits
}))
PY
    )
    [ -n "$payload" ] || { fallback agy Antigravity "probe timed out" > "$out"; return; }

    if jq -e '.ok == true' <<< "$payload" >/dev/null 2>&1; then
        echo "$payload" > "$out"
        cp "$out" "$CACHE/agy.json"
    else
        local err
        err=$(jq -r '.error // "unexpected response shape"' <<< "$payload" 2>/dev/null || echo "invalid payload")
        fallback agy Antigravity "$err" > "$out"
    fi
}

probe_claude &
probe_opencode &
probe_agy &
probe_codex &
wait

# Optional per-provider overrides, merged over each probe's output. For fields
# no API reports truthfully (e.g. agy's Google One plan lives behind a private
# gRPC and loadCodeAssist always says free-tier):
#   ~/.config/ai-usage/overrides.json -> {"agy": {"plan": "Pro"}}
OVERRIDES=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/ai-usage/overrides.json" 2>/dev/null) || OVERRIDES='{}'
jq -e . <<< "$OVERRIDES" >/dev/null 2>&1 || OVERRIDES='{}'

jq -n --arg t "$(date -u +%FT%TZ)" --argjson ov "$OVERRIDES" \
    '{updatedAt: $t, providers: [inputs | . * ($ov[.id] // {})]}' \
    "$TMP/claude.json" "$TMP/opencode.json" "$TMP/agy.json" "$TMP/codex.json"
