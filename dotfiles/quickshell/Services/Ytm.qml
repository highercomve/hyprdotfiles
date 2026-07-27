pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtMultimedia

Singleton {
    id: root

    property var searchResults: []
    property bool isSearching: false
    property string searchQuery: ""
    property string searchFilter: "songs"
    property string currentTitle: ""
    property string currentArtist: ""
    property string currentCover: ""
    property bool isPlaying: false
    property real position: 0
    property real duration: 0
    property bool isLoggedIn: false
    property var userPlaylists: []
    property string libraryError: ""
    property bool hasTrack: root.currentTitle.length > 0

    property int _searchRequestId: 0
    property int _radioRequestId: 0
    property int _playRequestId: 0
    property var _queue: []
    property int _queueIndex: -1
    property bool _libraryLoading: false

    property string _configDir: Quickshell.shellDir
    property string _bridgePath: _configDir + "/ytm_bridge.py"
    property string _pythonPath: _configDir + "/.venv/bin/python"
    property string _ytdlpPath: _configDir + "/.venv/bin/yt-dlp"

    MediaPlayer {
        id: mediaPlayer
        audioOutput: AudioOutput {}
        onPositionChanged: root.position = position / 1000
        onDurationChanged: root.duration = duration / 1000
        onPlaybackStateChanged: {
            root.isPlaying = playbackState === MediaPlayer.PlayingState
        }
        onErrorOccurred: (error, errorString) => {
            root.isPlaying = false
            root.currentTitle = "Playback error"
            console.warn("YTM MediaPlayer error:", error, errorString)
        }
    }

    Timer {
        interval: 1000
        running: root.isPlaying
        repeat: true
        onTriggered: root.position = mediaPlayer.position / 1000
    }

    Component.onCompleted: checkAuth()

    Process {
        id: bridgeProc
        command: []
        stdout: StdioCollector { onStreamFinished: root.handleBridge(text) }
    }

    Process {
        id: ytdlpProc
        command: []
        stdout: StdioCollector { onStreamFinished: root.handleYtdlp(text) }
    }

    property var _bridgeResolve: null

    function callBridge(type, query) {
        return new Promise((resolve) => {
            root._bridgeResolve = resolve
            const req = JSON.stringify({ type: type, query: query })
            bridgeProc.command = [root._pythonPath, root._bridgePath, req]
            bridgeProc.running = true
        })
    }

    function handleBridge(output) {
        let result = { error: "bridge failed" }
        try {
            result = JSON.parse(output.trim())
        } catch (e) {
            result = { error: e.toString() }
        }
        if (root._bridgeResolve) {
            root._bridgeResolve(result)
            root._bridgeResolve = null
        }
    }

    function checkAuth() {
        callBridge("check_auth").then((res) => {
            root.isLoggedIn = res.data?.authenticated || false
            if (root.isLoggedIn) root.getLibrary()
        })
    }

    function getLibrary() {
        if (root._libraryLoading) return
        root._libraryLoading = true
        callBridge("library_playlists").then((res) => {
            root.userPlaylists = res?.data || []
            root.libraryError = res?.error || ""
            root._libraryLoading = false
        })
    }

    function search(query, filter) {
        const requestId = ++root._searchRequestId
        if (!query.trim()) {
            root.searchResults = []
            root.isSearching = false
            return
        }
        root.isSearching = true
        root.searchQuery = query
        if (filter) root.searchFilter = filter
        callBridge("search", { query: query, filter: filter || root.searchFilter }).then((res) => {
            if (requestId !== root._searchRequestId) return
            root.searchResults = res.data || []
            root.isSearching = false
        })
    }

    function startRadio(videoId) {
        const requestId = ++root._radioRequestId
        callBridge("radio", videoId).then((res) => {
            if (requestId !== root._radioRequestId) return
            if (res.data?.length > 0) {
                root._queue = res.data
                    .filter((track) => track.videoId)
                    .map((track) => ({
                        videoId: track.videoId,
                        title: track.title,
                        artist: track.artists?.[0]?.name,
                        cover: track.thumbnails?.length ? track.thumbnails[track.thumbnails.length - 1]?.url : ""
                    }))
                root._queueIndex = 0
                playCurrent()
            }
        })
    }

    function playCurrent() {
        const track = root._queue[root._queueIndex]
        if (track) root.play(track.videoId, track.title, track.artist, track.cover, false)
    }

    property var _ytdlpResolve: null

    function extractAudioUrl(videoId) {
        return new Promise((resolve) => {
            root._ytdlpResolve = resolve
            ytdlpProc.command = [root._ytdlpPath, "-f", "bestaudio[ext=m4a]/bestaudio", "-g", "https://youtube.com/watch?v=" + videoId]
            ytdlpProc.running = true
        })
    }

    function handleYtdlp(output) {
        const url = output.trim()
        if (root._ytdlpResolve) {
            root._ytdlpResolve(url)
            root._ytdlpResolve = null
        }
    }

    function play(videoId, title, artist, cover, resetQueue) {
        if (resetQueue) {
            root._radioRequestId += 1
            root._queue = [{ videoId: videoId, title: title, artist: artist, cover: cover }]
            root._queueIndex = 0
        }
        const requestId = ++root._playRequestId
        root.currentTitle = title || "Loading..."
        root.currentArtist = artist || ""
        root.currentCover = cover || ""
        root.stop(false)
        extractAudioUrl(videoId).then((url) => {
            if (requestId !== root._playRequestId) return
            if (!url) {
                root.currentTitle = "Error loading stream"
                return
            }
            root.currentTitle = title || "Unknown Title"
            mediaPlayer.source = url
            mediaPlayer.play()
            root.isPlaying = true
        })
    }

    function next() {
        if (root._queueIndex < 0 || root._queueIndex >= root._queue.length - 1) return
        root._queueIndex += 1
        playCurrent()
    }

    function previous() {
        if (root.position > 5) {
            root.seek(0)
            return
        }
        if (root._queueIndex <= 0) return
        root._queueIndex -= 1
        playCurrent()
    }

    function pause() {
        root._playRequestId += 1
        mediaPlayer.pause()
        root.isPlaying = false
    }

    function resume() {
        mediaPlayer.play()
        root.isPlaying = true
    }

    function stop(invalidatePending) {
        if (invalidatePending) root._playRequestId += 1
        mediaPlayer.stop()
        root.isPlaying = false
    }

    function seek(pos) {
        mediaPlayer.setPosition(pos * 1000)
        root.position = pos
    }
}
