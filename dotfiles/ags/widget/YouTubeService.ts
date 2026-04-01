import GObject, { register, property } from "ags/gobject"
import GLib from "gi://GLib"
import Gio from "gi://Gio"
import Gst from "gi://Gst?version=1.0"
import App from "ags/gtk4/app"

const MPRIS_XML = `
<node>
  <interface name="org.mpris.MediaPlayer2">
    <method name="Raise"/>
    <method name="Quit"/>
    <property name="CanQuit" type="b" access="read"/>
    <property name="CanRaise" type="b" access="read"/>
    <property name="HasTrackList" type="b" access="read"/>
    <property name="Identity" type="s" access="read"/>
    <property name="SupportedUriSchemes" type="as" access="read"/>
    <property name="SupportedMimeTypes" type="as" access="read"/>
  </interface>
  <interface name="org.mpris.MediaPlayer2.Player">
    <method name="Next"/>
    <method name="Previous"/>
    <method name="Pause"/>
    <method name="PlayPause"/>
    <method name="Stop"/>
    <method name="Play"/>
    <method name="Seek">
      <arg direction="in" name="Offset" type="x"/>
    </method>
    <method name="SetPosition">
      <arg direction="in" name="TrackId" type="o"/>
      <arg direction="in" name="Position" type="x"/>
    </method>
    <method name="OpenUri">
      <arg direction="in" name="Uri" type="s"/>
    </method>
    <property name="PlaybackStatus" type="s" access="read"/>
    <property name="LoopStatus" type="s" access="readwrite"/>
    <property name="Rate" type="d" access="readwrite"/>
    <property name="Shuffle" type="b" access="readwrite"/>
    <property name="Metadata" type="a{sv}" access="read"/>
    <property name="Volume" type="d" access="readwrite"/>
    <property name="Position" type="x" access="read"/>
    <property name="MinimumRate" type="d" access="read"/>
    <property name="MaximumRate" type="d" access="read"/>
    <property name="CanGoNext" type="b" access="read"/>
    <property name="CanGoPrevious" type="b" access="read"/>
    <property name="CanPlay" type="b" access="read"/>
    <property name="CanPause" type="b" access="read"/>
    <property name="CanSeek" type="b" access="read"/>
    <property name="CanControl" type="b" access="read"/>
  </interface>
</node>`

try { Gst.init(null) } catch (e) {}

function execAsync(cmd: string | string[]): Promise<string> {
    return new Promise((resolve, reject) => {
        try {
            const proc = Gio.Subprocess.new(typeof cmd === "string" ? cmd.split(" ") : cmd, Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE)
            proc!.communicate_utf8_async(null, null, (proc, res) => {
                try {
                    const [, stdout, stderr] = proc!.communicate_utf8_finish(res)
                    if (proc!.get_successful()) resolve(stdout || "")
                    else reject(new Error(stderr || "failed"))
                } catch (e) { reject(e) }
            })
        } catch (e) { reject(e) }
    })
}

@register({ GTypeName: "YouTubeService" })
class YouTubeService extends GObject.Object {
    @property(Object) searchResults = []
    @property(Boolean) isSearching = false
    @property(String) searchQuery = ""
    @property(String) searchFilter = "songs"
    @property(String) currentTitle = ""
    @property(String) currentArtist = ""
    @property(String) currentCover = ""
    @property(Boolean) isPlaying = false
    @property(Number) position = 0
    @property(Number) duration = 0
    @property(Boolean) isLoggedIn = false
    @property(String) loginCode = ""
    @property(String) loginUrl = ""
    @property(Object) userPlaylists = []

    private bridgeDir = GLib.get_home_dir() + "/Code/hyprconfig/dotfiles/ags"
    private bridgePath = this.bridgeDir + "/ytm_bridge.py"
    private pythonPath = this.bridgeDir + "/.venv/bin/python"
    private ytdlpPath = this.bridgeDir + "/.venv/bin/yt-dlp"
    private playbin: Gst.Element | null = null
    private syncTimer: any = null
    private dbus: any = null
    private busOwnerId: number = 0
    private busSignalId: number = 0

    constructor() {
        super()
        this.setupPlayer()
        this.checkAuth()
        this.startSync()
        this.setupMpris()
    }

    private setupMpris() {
        try {
            // @ts-ignore
            this.dbus = Gio.DBusExportedObject.wrapJSObject(MPRIS_XML, this)
            this.busOwnerId = Gio.bus_own_name(Gio.BusType.SESSION, "org.mpris.MediaPlayer2.YouTubeMusic", Gio.BusNameOwnerFlags.NONE,
                (conn) => this.dbus.export(conn, "/org/mpris/MediaPlayer2"), null, null)
        } catch (e) {}
    }

    private notifyMpris(prop: string) {
        if (!this.dbus) return
        try {
            if (prop === "PlaybackStatus") this.dbus.emit_property_changed("PlaybackStatus", new GLib.Variant("s", this.PlaybackStatus))
            else if (prop === "Metadata") this.dbus.emit_property_changed("Metadata", new GLib.Variant("a{sv}", this.Metadata))
        } catch (e) {}
    }

    // --- MPRIS Interface Implementation ---
    Raise() {}
    Quit() { this.stop() }
    
    get CanQuit() { return true }
    set CanQuit(_) {}
    
    get CanRaise() { return false }
    set CanRaise(_) {}
    
    get HasTrackList() { return false }
    set HasTrackList(_) {}
    
    get Identity() { return "YouTube Music" }
    set Identity(_) {}
    
    get SupportedUriSchemes() { return ["https"] }
    set SupportedUriSchemes(_) {}
    
    get SupportedMimeTypes() { return ["audio/mpeg"] }
    set SupportedMimeTypes(_) {}

    Next() {}
    Previous() {}
    Pause() { this.pause() }
    PlayPause() { this.isPlaying ? this.pause() : this.resume() }
    Stop() { this.stop() }
    Play() { this.resume() }
    Seek(offset: number) { this.set_position(this.position + (offset / 1000000)) }
    SetPosition(id: string, pos: number) { this.set_position(pos / 1000000) }
    OpenUri(uri: string) {}

    get PlaybackStatus() { return this.isPlaying ? "Playing" : "Paused" }
    set PlaybackStatus(_) {}

    get Metadata() {
        return {
            "mpris:trackid": new GLib.Variant("o", "/org/mpris/MediaPlayer2/Track/0"),
            "mpris:length": new GLib.Variant("x", Math.floor(this.duration * 1000000)),
            "xesam:title": new GLib.Variant("s", this.currentTitle || "YouTube Music"),
            "xesam:artist": new GLib.Variant("as", [this.currentArtist || "Unknown Artist"]),
            "mpris:artUrl": new GLib.Variant("s", this.currentCover || "")
        }
    }
    set Metadata(_) {}

    get Volume() { return 1.0 }
    set Volume(_) {}

    get Position() { return Math.floor(this.position * 1000000) }
    set Position(_) {}

    get LoopStatus() { return "None" }
    set LoopStatus(_) {}

    get Rate() { return 1.0 }
    set Rate(_) {}

    get Shuffle() { return false }
    set Shuffle(_) {}

    get MinimumRate() { return 1.0 }
    set MinimumRate(_) {}

    get MaximumRate() { return 1.0 }
    set MaximumRate(_) {}

    get CanGoNext() { return false }
    set CanGoNext(_) {}

    get CanGoPrevious() { return false }
    set CanGoPrevious(_) {}

    get CanPlay() { return true }
    set CanPlay(_) {}

    get CanPause() { return true }
    set CanPause(_) {}

    get CanSeek() { return true }
    set CanSeek(_) {}

    get CanControl() { return true }
    set CanControl(_) {}

    // --- Logic ---
    private startSync() {
        if (this.syncTimer) GLib.source_remove(this.syncTimer)
        this.syncTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
            if (this.playbin && this.isPlaying) {
                const [ok_pos, pos] = this.playbin.query_position(Gst.Format.TIME)
                const [ok_dur, dur] = this.playbin.query_duration(Gst.Format.TIME)
                if (ok_pos) { this.position = pos / Gst.SECOND; this.notify("position") }
                if (ok_dur) { this.duration = dur / Gst.SECOND; this.notify("duration") }
            }
            return true
        })
    }

    set_position(pos: number) {
        if (this.playbin) this.playbin.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH | Gst.SeekFlags.KEY_UNIT, pos * Gst.SECOND)
    }

    private async callBridge(type: string, query?: any): Promise<any> {
        try {
            const req = JSON.stringify({ type, query })
            const stdout = await execAsync([this.pythonPath, this.bridgePath, req])
            return JSON.parse(stdout)
        } catch (e) { return { error: e.toString() } }
    }

    async checkAuth() {
        const res = await this.callBridge("check_auth")
        this.isLoggedIn = res.data?.authenticated || false
        this.notify("is-logged-in")
        if (this.isLoggedIn) this.getLibrary()
    }

    async getLibrary() {
        const res = await this.callBridge("library_playlists")
        this.userPlaylists = res.data || []
        this.notify("user-playlists")
    }

    private setupPlayer() {
        try {
            this.playbin = Gst.ElementFactory.make("playbin", "ytm-playbin")
            if (this.playbin) {
                this.playbin.set_property("name", "YouTubeMusic")
                const bus = this.playbin.get_bus()
                if (bus) {
                    bus.add_signal_watch()
                    this.busSignalId = bus.connect("message", (bus: Gst.Bus, msg: Gst.Message) => {
                        if (!msg) return
                        if (msg.type === Gst.MessageType.EOS || msg.type === Gst.MessageType.ERROR) {
                            this.isPlaying = false; this.notify("is-playing"); this.notifyMpris("PlaybackStatus")
                        }
                    })
                }
            }
        } catch (e) {}
    }

    async search(query: string, filter: string | null = null) {
        if (!query) { this.searchResults = []; this.notify("search-results"); return }
        this.isSearching = true; this.notify("is-searching")
        const result = await this.callBridge("search", { query, filter })
        this.searchResults = result.data || []
        this.isSearching = false; this.notify("is-searching"); this.notify("search-results")
    }

    async startRadio(videoId: string) {
        const res = await this.callBridge("radio", videoId)
        if (res.data?.length > 0) {
            const first = res.data[0]
            this.play(first.videoId, first.title, first.artists?.[0]?.name)
        }
    }

    async extractAudioUrl(videoId: string): Promise<string> {
        try {
            const url = `https://youtube.com/watch?v=${videoId}`
            const stdout = await execAsync([this.ytdlpPath, "-f", "bestaudio", "-g", url])
            return stdout.trim()
        } catch (e) { return "" }
    }

    async play(videoId: string, title?: string, artist?: string, cover?: string) {
        if (!this.playbin) return
        this.currentTitle = title || "Loading..."; this.currentArtist = artist || ""; this.currentCover = cover || ""
        this.notify("current-title"); this.notify("current-artist"); this.notify("current-cover"); this.notifyMpris("Metadata")
        this.stop()
        const audioUrl = await this.extractAudioUrl(videoId)
        if (!audioUrl) { this.currentTitle = "Error loading stream"; this.notify("current-title"); this.notifyMpris("Metadata"); return }
        this.currentTitle = title || "Unknown Title"; this.notify("current-title"); this.notifyMpris("Metadata")
        this.playbin.set_property("uri", audioUrl)
        this.playbin.set_state(Gst.State.PLAYING)
        this.isPlaying = true; this.notify("is-playing"); this.notifyMpris("PlaybackStatus")
    }

    pause() {
        if (!this.playbin) return
        this.playbin.set_state(Gst.State.PAUSED); this.isPlaying = false; this.notify("is-playing"); this.notifyMpris("PlaybackStatus")
    }

    resume() {
        if (!this.playbin) return
        this.playbin.set_state(Gst.State.PLAYING); this.isPlaying = true; this.notify("is-playing"); this.notifyMpris("PlaybackStatus")
    }

    stop() {
        if (!this.playbin) return
        this.playbin.set_state(Gst.State.NULL); this.isPlaying = false; this.notify("is-playing"); this.notifyMpris("PlaybackStatus")
    }

    destroy() {
        if (this.syncTimer) {
            GLib.source_remove(this.syncTimer);
            this.syncTimer = null;
        }
        if (this.playbin) {
            const bus = this.playbin.get_bus();
            if (bus) {
                if (this.busSignalId) bus.disconnect(this.busSignalId);
                bus.remove_signal_watch();
            }
            this.playbin.set_state(Gst.State.NULL);
            this.playbin = null;
        }
        if (this.busOwnerId) {
            Gio.bus_unown_name(this.busOwnerId);
            this.busOwnerId = 0;
        }
    }
}

const service = new YouTubeService()
export default service