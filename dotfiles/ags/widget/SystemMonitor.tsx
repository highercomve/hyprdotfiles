import { createBinding } from "ags"
import GLib from "gi://GLib"
import GObject, { register, property } from "ags/gobject"

const SCRIPTS_DIR = GLib.get_home_dir() + "/.config/hypr/user_settings"

@register({ GTypeName: "SystemState" })
class SystemState extends GObject.Object {
	@property(Number) cpu = 0
	@property(String) memory = ""
	@property(Number) temp = 0

	private prevCpu = { total: 0, idle: 0 }

	constructor() {
		super()
		this.startPolling()
	}

	startPolling() {
		// Poll every 2 seconds
		GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
			this.updateCpu()
			this.updateMemory()
			this.updateTemp()
			return true // repeat
		})
	}

	updateCpu() {
		try {
			const [ok, contents] = GLib.file_get_contents("/proc/stat")
			if (!ok) return
			const lines = new TextDecoder().decode(contents).split("\n")
			const cpuLine = lines.find((line) => line.startsWith("cpu "))
			if (!cpuLine) return

			const parts = cpuLine
				.split(/\s+/) // Use regex for splitting by whitespace
				.filter((p) => p !== "")
				.slice(1)
				.map(Number)
			// user, nice, system, idle, iowait, irq, softirq, steal
			// idle = idle + iowait
			const idle = parts[3] + parts[4]
			const total = parts.reduce((a, b) => a + b, 0)

			const deltaTotal = total - this.prevCpu.total
			const deltaIdle = idle - this.prevCpu.idle

			if (deltaTotal > 0) {
				this.cpu = Math.round((1 - deltaIdle / deltaTotal) * 100)
			}

			this.prevCpu = { total, idle }
		} catch (e) {
			console.error(e)
		}
	}

	updateMemory() {
		try {
			const [ok, contents] = GLib.file_get_contents("/proc/meminfo")
			if (!ok) return
			const text = new TextDecoder().decode(contents)
			const totalMatch = text.match(/MemTotal:\s+(\d+)/)
			const availableMatch = text.match(/MemAvailable:\s+(\d+)/)

			if (totalMatch && availableMatch) {
				const total = parseInt(totalMatch[1])
				const available = parseInt(availableMatch[1])
				const used = total - available
				// Convert to GB (1 GB = 1024 * 1024 KB)
				this.memory = (used / 1048576).toFixed(1)
			}
		} catch (e) {
			console.error(e)
		}
	}

	updateTemp() {
		try {
			// Using the same hwmon path as in Waybar config for consistency
			const [ok, contents] = GLib.file_get_contents(
				"/sys/class/hwmon/hwmon4/temp3_input",
			)
			if (!ok) return
			const temp = parseInt(new TextDecoder().decode(contents).trim())
			this.temp = Math.round(temp / 1000)
		} catch (e) {
			console.error(e)
		}
	}
}

const systemState = new SystemState()

export default function SystemMonitor() {
	return (
		<button
			class="system-monitor module-group"
			onClicked={() =>
				GLib.spawn_command_line_async(`${SCRIPTS_DIR}/system-monitor.sh`)
			}
		>
			<box spacing={8}>
				<label
					label={createBinding(systemState, "cpu").as((v) => `  ${v}%`)}
					tooltipText="CPU Usage"
				/>
				<label
					label={createBinding(systemState, "memory").as((v) => ` ${v}G`)}
					tooltipText="Memory Usage"
				/>
				<label
					label={createBinding(systemState, "temp").as((v) => ` ${v}°C`)}
					tooltipText="CPU Temperature"
				/>
			</box>
		</button>
	)
}
