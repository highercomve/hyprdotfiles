import GObject, { register, property } from "ags/gobject"
import GLib from "gi://GLib"

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

            // Poll for changes
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
                const current = Number(exec("brightnessctl get"))
                if (!isNaN(current)) {
                    const newVal = current / this._max
                    if (Math.abs(newVal - this.screen) > 0.01) {
                        this.screen = newVal
                        this.notify("screen")
                    }
                }
                return true
            })
        } catch (error) {
            console.error("BrightnessService init error:", error)
            this.available = false
        }
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
