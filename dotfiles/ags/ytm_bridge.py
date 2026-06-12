import sys
import json
import os
from ytmusicapi import YTMusic, OAuthCredentials

BRIDGE_DIR = os.path.dirname(os.path.abspath(__file__))
OAUTH_FILE = os.path.join(BRIDGE_DIR, "oauth.json")
CREDENTIALS_FILE = os.path.join(BRIDGE_DIR, "credentials.json")
BROWSER_FILE = os.path.join(BRIDGE_DIR, "browser.json")

def friendly_error(e):
    """Turn a raw ytmusicapi/HTTP exception into a short, user-facing message.
    A 400 or a 'runs' KeyError on an empty body almost always means the stored
    browser/oauth auth is stale or invalid, not a transient network blip."""
    msg = str(e)
    low = msg.lower()
    if any(s in low for s in ("400", "401", "403", "unauthorized", "runs", "on {}")):
        return "YouTube Music auth is invalid or expired — re-link your account (refresh browser.json / oauth.json)."
    return msg

def get_yt_instance():
    try:
        if os.path.exists(BROWSER_FILE): return YTMusic(BROWSER_FILE)
        if os.path.exists(OAUTH_FILE) and os.path.exists(CREDENTIALS_FILE):
            with open(CREDENTIALS_FILE, 'r') as f: creds_data = json.load(f)
            creds = OAuthCredentials(client_id=creds_data.get("client_id"), client_secret=creds_data.get("client_secret"))
            return YTMusic(auth=OAUTH_FILE, oauth_credentials=creds)
        if os.path.exists(OAUTH_FILE): return YTMusic(OAUTH_FILE)
        return None
    except: return None

def main():
    if len(sys.argv) < 2: return
    try:
        req = json.loads(sys.argv[1])
        cmd_type = req.get("type")
        raw_query = req.get("query")
        if isinstance(raw_query, dict):
            query = raw_query.get("query")
            filter_type = raw_query.get("filter")
        else:
            query = raw_query
            filter_type = req.get("filter")
    except: return

    try:
        if cmd_type == "check_auth":
            is_auth = (os.path.exists(BROWSER_FILE) or os.path.exists(OAUTH_FILE))
            print(json.dumps({"type": "check_auth", "data": {"authenticated": is_auth}}))
            return

        yt = get_yt_instance()
        if not yt:
            print(json.dumps({"error": "Not authenticated"}))
            return

        if cmd_type == "search":
            results = yt.search(query, filter=filter_type)
            clean = []
            for r in results:
                item = {"type": r.get("resultType"), "name": r.get("title") or r.get("artist"), "id": r.get("videoId") or r.get("browseId") or r.get("playlistId")}
                if "artists" in r and r["artists"]: item["artist"] = r["artists"][0].get("name")
                if "thumbnails" in r and r["thumbnails"]: item["thumbnail"] = r["thumbnails"][-1].get("url")
                clean.append(item)
            print(json.dumps({"type": "search", "data": clean}))

        elif cmd_type == "radio":
            results = yt.get_watch_playlist(videoId=query, limit=20)
            print(json.dumps({"type": "radio", "data": results.get("tracks", [])}))

        elif cmd_type == "library_playlists":
            try:
                results = yt.get_library_playlists(limit=20)
                print(json.dumps({"type": "library_playlists", "data": results}))
            except Exception as e:
                # Surface the failure once instead of silently returning []. The
                # caller shows this to the user and does not retry in a loop.
                print(json.dumps({"type": "library_playlists", "data": [], "error": friendly_error(e)}))

        elif cmd_type == "playlist":
            results = yt.get_playlist(query)
            print(json.dumps({"type": "playlist", "data": results}))

    except Exception as e:
        # Always emit a single structured JSON line — never a raw traceback to
        # stderr (that is what used to spam bridge.log).
        print(json.dumps({"error": friendly_error(e)}))

if __name__ == "__main__":
    main()