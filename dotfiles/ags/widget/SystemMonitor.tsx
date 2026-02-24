import { createBinding } from "ags"
import GLib from "gi://GLib"
import Gio from "gi://Gio"
import GObject, { register, property } from "ags/gobject"

const SCRIPTS_DIR = GLib.get_home_dir() + "/.config/hypr/user_settings"

@register({ GTypeName: "SystemState" })
class SystemState extends GObject.Object {
	@property(Number) cpu = 0
	@property(String) memory = ""
	@property(Number) temp = 0

	private prevCpu = { total: 0, idle: 0 }
	private hwmonPath = ""

	constructor() {
		super()
		this.findHwmon()
		this.startPolling()
	}

	findHwmon() {
		try {
			const dir = Gio.File.new_for_path("/sys/class/hwmon")
			const enumerator = dir.enumerate_children("standard::name", Gio.FileQueryInfoFlags.NONE, null)
			let info
			while ((info = enumerator.next_file(null)) !== null) {
				const name = info.get_name()
				const path = `/sys/class/hwmon/${name}`

				const hasTemp1 = GLib.file_test(`${path}/temp1_input`, GLib.FileTest.EXISTS)
				const hasTemp3 = GLib.file_test(`${path}/temp3_input`, GLib.FileTest.EXISTS)

				if (hasTemp1 || hasTemp3) {
					const [ok, contents] = GLib.file_get_contents(`${path}/name`)
					if (ok) {
						const nameStr = new TextDecoder().decode(contents).trim()
						if (nameStr === "coretemp" || nameStr === "k10temp" || nameStr === "zenpower") {
							this.hwmonPath = hasTemp1 ? `${path}/temp1_input` : `${path}/temp3_input`
							break
						}
					}
					// Fallback to whichever exists if not the specific CPU one
					if (!this.hwmonPath) {
						this.hwmonPath = hasTemp1 ? `${path}/temp1_input` : `${path}/temp3_input`
					}
				}
			}
		} catch (e) {
			console.error(e)
			this.hwmonPath = "/sys/class/hwmon/hwmon4/temp3_input" // fallback
		}
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
		const file = Gio.File.new_for_path("/proc/stat")
		file.load_contents_async(null, (_obj, res) => {
			try {
				const [ok, contents] = file.load_contents_finish(res)
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
		})
	}

	updateMemory() {
		const file = Gio.File.new_for_path("/proc/meminfo")
		file.load_contents_async(null, (_obj, res) => {
			try {
				const [ok, contents] = file.load_contents_finish(res)
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
		})
	}

	updateTemp() {
		if (!this.hwmonPath) return
		const file = Gio.File.new_for_path(this.hwmonPath)
		file.load_contents_async(null, (_obj, res) => {
			try {
				const [ok, contents] = file.load_contents_finish(res)
				if (!ok) return
				const temp = parseInt(new TextDecoder().decode(contents).trim())
				this.temp = Math.round(temp / 1000)
			} catch (e) {
				console.error(e)
			}
		})
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
					class="cpu"
					label={createBinding(systemState, "cpu").as((v) => `  ${v}%`)}
					tooltipText="CPU Usage"
				/>
				<label
					class="memory"
					label={createBinding(systemState, "memory").as((v) => ` ${v}G`)}
					tooltipText="Memory Usage"
				/>
				<label
					class="temp"
					label={createBinding(systemState, "temp").as((v) => ` ${v}°C`)}
					tooltipText="CPU Temperature"
				/>
			</box>
		</button>
	)
}
