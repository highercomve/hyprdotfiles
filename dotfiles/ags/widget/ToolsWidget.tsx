import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import GLib from "gi://GLib"
import PowerProfiles from "gi://AstalPowerProfiles"
import GObject, { register, property } from "ags/gobject"

const SCRIPTS_DIR = GLib.get_home_dir() + "/.config/hypr/scripts"
const pp = PowerProfiles.get_default()

@register({ GTypeName: "ToolsState" })
class ToolsState extends GObject.Object {
	@property(Boolean) reveal = false
	@property(String) idle = "" // "active" | "inactive"
	@property(String) sunset = ""
	@property(String) record = ""

	constructor() {
		super()
		this.startPolling()
	}

	startPolling() {
		// Poll every 2 seconds
		GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
			this.checkStatus(`${SCRIPTS_DIR}/hypridle.sh status`, "idle")
			this.checkStatus(`${SCRIPTS_DIR}/hyprsunset.sh status`, "sunset")
			this.checkStatus(`${SCRIPTS_DIR}/record.sh status`, "record")
			return true // repeat
		})
	}

	checkStatus(cmd: string, prop: string) {
		try {
			const [parsed, argv] = GLib.shell_parse_argv(cmd)
			if (!parsed || !argv) return

			const [success, out, err, status] = GLib.spawn_sync(
				null,
				argv,
				null,
				GLib.SpawnFlags.SEARCH_PATH,
				null,
			)

			if (!success || status !== 0 || !out) return

			const text = new TextDecoder().decode(out)
			// Parse JSON
			try {
				const json = JSON.parse(text)
				const val = json.class || json.alt || json.text || ""

				if ((this as any)[prop] !== val) (this as any)[prop] = val
			} catch (e) {}
		} catch (e) {
			console.error(e)
		}
	}
}

const toolsState = new ToolsState()

function ToolButton({
	icon,
	command,
	tooltip,
}: {
	icon: string
	command: string
	tooltip?: string
}) {
	return (
		<button
			class="tool-button"
			tooltipText={tooltip}
			onClicked={() => {
				try {
					GLib.spawn_command_line_async(command)
				} catch (e) {
					console.error(e)
				}
			}}
		>
			<Gtk.Image iconName={icon} />
		</button>
	)
}

function PowerProfileButton() {
	const profiles = ["power-saver", "balanced", "performance"]
	const prettyNames: Record<string, string> = {
		"power-saver": "Power Saver",
		balanced: "Balanced",
		performance: "Performance",
	}
	const icons: Record<string, string> = {
		"power-saver": "power-profile-power-saver-symbolic",
		balanced: "power-profile-balanced-symbolic",
		performance: "power-profile-performance-symbolic",
	}

	return (
		<button
			class="tool-button"
			onClicked={() => {
				const current = pp.active_profile
				const index = profiles.indexOf(current)
				const next = profiles[(index + 1) % profiles.length]
				pp.set_active_profile(next)
			}}
			tooltipText={createBinding(pp, "active-profile").as(
				(p) => prettyNames[p] || p,
			)}
		>
			<Gtk.Image
				iconName={createBinding(pp, "active-profile").as(
					(p) => icons[p] || "power-profile-balanced-symbolic",
				)}
			/>
		</button>
	)
}

export default function ToolsRow() {
	return (
		<box class="group-tools module-group">
			<Gtk.Revealer
				revealChild={createBinding(toolsState, "reveal")}
				transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}
				transitionDuration={300}
			>
				<box class="tools-container" spacing={4}>
					<ToolButton
						icon="edit-copy-symbolic"
						command={`${SCRIPTS_DIR}/cliphist.sh`}
						tooltip="Clipboard Manager"
					/>
					<button
						class={createBinding(toolsState, "idle").as(
							(s) => `tool-button ${s === "active" ? "active" : ""}`,
						)}
						tooltipText="Idle Inhibitor"
						onClicked={() => {
							GLib.spawn_command_line_async(`${SCRIPTS_DIR}/hypridle.sh toggle`)
							// immediate update?
							setTimeout(
								() =>
									toolsState.checkStatus(
										`${SCRIPTS_DIR}/hypridle.sh status`,
										"idle",
									),
								200,
							)
						}}
					>
						<Gtk.Image
							iconName={createBinding(toolsState, "idle").as(
								(s) =>
									s === "active"
										? "weather-clear-symbolic"
										: "weather-clear-symbolic", // Icon usually stays, color changes
							)}
						/>
					</button>

					<button
						class={createBinding(toolsState, "sunset").as(
							(s) => `tool-button ${s === "active" ? "active" : ""}`,
						)}
						tooltipText="Night Light"
						onClicked={() => {
							GLib.spawn_command_line_async(
								`${SCRIPTS_DIR}/hyprsunset.sh toggle`,
							)
							setTimeout(
								() =>
									toolsState.checkStatus(
										`${SCRIPTS_DIR}/hyprsunset.sh status`,
										"sunset",
									),
								200,
							)
						}}
					>
						<Gtk.Image iconName="weather-clear-night-symbolic" />
					</button>

					<button
						class={createBinding(toolsState, "record").as(
							(s) => `tool-button ${s === "recording" ? "active" : ""}`,
						)}
						tooltipText="Screen Record"
						onClicked={() => {
							GLib.spawn_command_line_async(`${SCRIPTS_DIR}/record.sh toggle`)
							setTimeout(
								() =>
									toolsState.checkStatus(
										`${SCRIPTS_DIR}/record.sh status`,
										"record",
									),
								200,
							)
						}}
					>
						<Gtk.Image iconName="media-record-symbolic" />
					</button>

					<PowerProfileButton />
				</box>
			</Gtk.Revealer>

			<button
				class="tools-toggle"
				onClicked={() => {
					toolsState.reveal = !toolsState.reveal
				}}
				tooltipText="Tools"
			>
				<Gtk.Image iconName="preferences-system-symbolic" />
			</button>
		</box>
	)
}
