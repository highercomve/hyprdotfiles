import GObject, { register, property } from "ags/gobject"
import GLib from "gi://GLib"
import Gio from "gi://Gio"

function exec(argv: string[]): Promise<string> {
    return new Promise((resolve, reject) => {
        try {
            const proc = Gio.Subprocess.new(
                argv,
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE,
            )
            proc.communicate_utf8_async(null, null, (process, result) => {
                try {
                    const [, stdout, stderr] = process.communicate_utf8_finish(result)
                    if (!process.get_successful()) {
                        reject(new Error(stderr || `Command failed: ${argv[0]}`))
                        return
                    }
                    resolve((stdout || "").trim())
                } catch (error) {
                    reject(error)
                }
            })
        } catch (error) {
            reject(error)
        }
    })
}

@register({ GTypeName: "BrightnessService" })
class BrightnessService extends GObject.Object {
    @property(Number) screen = 0
    @property(Boolean) available = false

    private _max = 0
    private monitor: Gio.FileMonitor | null = null
    private timerId: number | null = null
    private debounceTimer: number | null = null
    private readInFlight = false
    private destroyed = false

    constructor() {
        super()
        void this.initialize()
    }

    private async initialize() {
        try {
            const devices = await exec(["brightnessctl", "--class=backlight", "list"])
            if (this.destroyed || devices.includes("No devices found") || !devices) return

            const maxStr = await exec(["brightnessctl", "max"])
            const max = Number(maxStr)
            if (this.destroyed || !Number.isFinite(max) || max <= 0) return

            this._max = max
            this.available = true
            await this.readBrightness()
            if (!this.destroyed) this.startMonitoring()
        } catch (error) {
            if (!this.destroyed) console.error("BrightnessService init error:", error)
        }
    }

    private startMonitoring() {
        try {
            const backlightDir = Gio.File.new_for_path("/sys/class/backlight")
            const enumerator = backlightDir.enumerate_children(
                "standard::name",
                Gio.FileQueryInfoFlags.NONE,
                null,
            )
            let info
            let brightnessPath = ""
            while ((info = enumerator.next_file(null)) !== null) {
                brightnessPath = `/sys/class/backlight/${info.get_name()}/brightness`
                break
            }
            enumerator.close(null)

            if (!brightnessPath) {
                this.startPolling()
                return
            }

            const file = Gio.File.new_for_path(brightnessPath)
            this.monitor = file.monitor_file(Gio.FileMonitorFlags.NONE, null)
            this.monitor.connect("changed", () => {
                if (this.debounceTimer) GLib.source_remove(this.debounceTimer)
                this.debounceTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
                    void this.readBrightness()
                    this.debounceTimer = null
                    return GLib.SOURCE_REMOVE
                })
            })
        } catch (error) {
            console.error("FileMonitor failed, falling back to polling:", error)
            this.startPolling()
        }
    }

    private startPolling() {
        if (this.timerId) GLib.source_remove(this.timerId)
        this.timerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
            void this.readBrightness()
            return GLib.SOURCE_CONTINUE
        })
    }

    private async readBrightness() {
        if (this.destroyed || !this.available || !this._max || this.readInFlight) return
        this.readInFlight = true
        try {
            const output = await exec(["brightnessctl", "get"])
            if (this.destroyed || !output) return

            const current = Number(output)
            if (!Number.isFinite(current)) return

            const newValue = Math.max(0, Math.min(1, current / this._max))
            if (Math.abs(newValue - this.screen) > 0.01) this.screen = newValue
        } catch (error) {
            // Keep the last known value on transient brightnessctl failures.
        } finally {
            this.readInFlight = false
        }
    }

    destroy() {
        this.destroyed = true
        if (this.monitor) { this.monitor.cancel(); this.monitor = null }
        if (this.timerId) { GLib.source_remove(this.timerId); this.timerId = null }
        if (this.debounceTimer) { GLib.source_remove(this.debounceTimer); this.debounceTimer = null }
    }

    set screen_value(percent: number) {
        if (!this.available) return

        const value = Math.max(0, Math.min(1, percent))
        void exec(["brightnessctl", "set", `${Math.round(value * 100)}%`, "-q"])
            .catch(() => this.readBrightness())
        this.screen = value
    }

    get screen_value() {
        return this.screen
    }
}

const service = new BrightnessService()
export default service
