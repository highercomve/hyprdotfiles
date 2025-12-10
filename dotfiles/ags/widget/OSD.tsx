import { Astal, Gtk, Gdk } from "ags/gtk4"
import Audio from "gi://AstalWp"
import GObject, { register, property } from "ags/gobject"
import { createBinding } from "ags"
import GLib from "gi://GLib"

@register({ GTypeName: "OSDState" })
class OSDState extends GObject.Object {
	@property(Boolean) visible = false
	@property(Number) volume = 0
	@property(String) icon = "audio-volume-high-symbolic"

	private timeout: number | null = null
	private speaker = Audio.get_default()?.audio.defaultSpeaker

	constructor() {
		super()
		if (this.speaker) {
			this.speaker.connect("notify::volume", this.onUpdate.bind(this))
			this.speaker.connect("notify::mute", this.onUpdate.bind(this))
		}
	}

	onUpdate() {
		if (!this.speaker) return
		this.volume = this.speaker.volume
		this.icon = this.speaker.volumeIcon
		this.visible = true

		if (this.timeout) GLib.source_remove(this.timeout)
		this.timeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
			this.visible = false
			this.timeout = null
			return false
		})
	}
}

const osdState = new OSDState()

export default function OSD(monitor: Gdk.Monitor) {
	return (
		<Astal.Window
			name={`osd-${monitor}`} // This name might need to be unique differently, but object default toString helps
			namespace="osd"
			gdkmonitor={monitor}
			layer={Astal.Layer.OVERLAY}
			anchor={Astal.WindowAnchor.BOTTOM}
			marginBottom={60}
			visible={createBinding(osdState, "visible")}
		>
			<box
				class="osd-window"
				orientation={Gtk.Orientation.HORIZONTAL}
				spacing={16}
			>
				<Gtk.Image iconName={createBinding(osdState, "icon")} pixelSize={32} />
				<Gtk.LevelBar
					valign={Gtk.Align.CENTER}
					widthRequest={200}
					minValue={0}
					maxValue={1}
					value={createBinding(osdState, "volume")}
				/>
				<Gtk.Label
					label={createBinding(osdState, "volume").as(
						(v) => `${Math.round(v * 100)}%`,
					)}
					css="min-width: 40px; font-weight: bold;"
				/>
			</box>
		</Astal.Window>
	)
}
