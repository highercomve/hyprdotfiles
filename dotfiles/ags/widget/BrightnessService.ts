import GObject, { register, property } from "ags/gobject"
import GLib from "gi://GLib"
import Gio from "gi://Gio"

// Helper for sync execution
function exec(cmd: string): string {
    try {
        const [success, stdout] = GLib.spawn_command_line_sync(cmd)
        if (!success || !stdout) return ""
        return new TextDecoder().decode(stdout).trim()
    } catch (e) {
        console.error(`Error executing ${cmd}:`, e)
        return ""
    }
}

// Helper for async execution
function execAsync(cmd: string) {
    try {
        GLib.spawn_command_line_async(cmd)
    } catch (e) {
        console.error(`Error spawning ${cmd}:`, e)
    }
}

@register({ GTypeName: "BrightnessService" })
class BrightnessService extends GObject.Object {
    @property(Number) screen = 0
    @property(Boolean) available = false

    private _max = 0
    private monitor: Gio.FileMonitor | null = null
    private timerId: number | null = null
    private debounceTimer: number | null = null

    constructor() {
        super()

        try {
            // Check if any backlight device exists
            // brightnessctl --class=backlight list
            const devices = exec("brightnessctl --class=backlight list")
            if (devices.includes("No devices found") || !devices) {
                this.available = false
                return
            }

            // If we are here, we probably have a backlight device
            this.available = true

            // Get max brightness
            const maxStr = exec("brightnessctl max")
            this._max = Number(maxStr) || 1

            const currentStr = exec("brightnessctl get")
            this.screen = (Number(currentStr) || 0) / this._max

            // Watch sysfs for brightness changes instead of polling
            this.startMonitoring()
        } catch (error) {
            console.error("BrightnessService init error:", error)
            this.available = false
        }
    }

    private startMonitoring() {
        try {
            // Find the backlight device path
            const backlightDir = Gio.File.new_for_path("/sys/class/backlight")
            const enumerator = backlightDir.enumerate_children("standard::name", Gio.FileQueryInfoFlags.NONE, null)
            let info
            let brightnessPath = ""
            while ((info = enumerator.next_file(null)) !== null) {
                brightnessPath = `/sys/class/backlight/${info.get_name()}/brightness`
                break // use first device
            }
            enumerator.close(null)

            if (!brightnessPath) {
                // Fallback to polling at 1s if no sysfs path found
                this.timerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
                    this.readBrightness()
                    return true
                })
                return
            }

            const file = Gio.File.new_for_path(brightnessPath)
            this.monitor = file.monitor_file(Gio.FileMonitorFlags.NONE, null)
            this.monitor.connect("changed", () => {
                // Debounce to avoid flooding during slider drags
                if (this.debounceTimer) GLib.source_remove(this.debounceTimer)
                this.debounceTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
                    try {
                        this.readBrightness()
                    } finally {
                        this.debounceTimer = null
                    }
                    return false
                })
            })
        } catch (e) {
            console.error("FileMonitor failed, falling back to polling:", e)
            this.timerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
                this.readBrightness()
                return true
            })
        }
    }

    private readBrightness() {
        const current = Number(exec("brightnessctl get"))
        if (!isNaN(current)) {
            const newVal = current / this._max
            if (Math.abs(newVal - this.screen) > 0.01) {
                this.screen = newVal
                this.notify("screen")
            }
        }
    }

    destroy() {
        if (this.monitor) { this.monitor.cancel(); this.monitor = null }
        if (this.timerId) { GLib.source_remove(this.timerId); this.timerId = null }
        if (this.debounceTimer) { GLib.source_remove(this.debounceTimer); this.debounceTimer = null }
    }

    set screen_value(percent: number) {
        if (!this.available) return

        if (percent < 0) percent = 0
        if (percent > 1) percent = 1

        execAsync(`brightnessctl set ${Math.round(percent * 100)}% -q`)
        this.screen = percent
        this.notify("screen")
    }

    get screen_value() {
        return this.screen
    }
}

const service = new BrightnessService()
export default service
