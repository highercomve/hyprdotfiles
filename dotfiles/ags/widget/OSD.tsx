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
	private audio = Audio.get_default()?.audio
	private speaker: any = null
	private volumeHandlerId: number = 0
	private muteHandlerId: number = 0
	private defaultSpeakerHandlerId: number = 0
	private watchdogId: number | null = null
	private lastVolume: number | null = null
	private lastMute: boolean | null = null
	private lastIcon: string | null = null

	constructor() {
		super()
		this.bindSpeaker(false)
		// Re-bind when the user switches their default output device — otherwise
		// the OSD silently goes stale and leaks signal handlers on the old speaker.
		if (this.audio) {
			this.defaultSpeakerHandlerId = this.audio.connect(
				"notify::default-speaker",
				() => this.bindSpeaker(true),
			)
		}

		// AstalWp can occasionally stop delivering endpoint notifications after
		// PipeWire/WirePlumber has been running for a long time. Keep the signal
		// path fast, but periodically verify the live endpoint state as a fallback.
		this.watchdogId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
			const currentSpeaker = this.audio?.defaultSpeaker ?? null
			if (currentSpeaker !== this.speaker) {
				this.bindSpeaker(true)
			} else {
				this.syncSpeaker(true)
			}
			return true
		})
	}

	private bindSpeaker(show: boolean) {
		// Disconnect from previous speaker, if any
		if (this.speaker) {
			if (this.volumeHandlerId) this.speaker.disconnect(this.volumeHandlerId)
			if (this.muteHandlerId) this.speaker.disconnect(this.muteHandlerId)
			this.volumeHandlerId = 0
			this.muteHandlerId = 0
		}
		this.speaker = this.audio?.defaultSpeaker ?? null
		this.lastVolume = null
		this.lastMute = null
		this.lastIcon = null
		if (this.speaker) {
			this.volumeHandlerId = this.speaker.connect("notify::volume", this.onUpdate)
			this.muteHandlerId = this.speaker.connect("notify::mute", this.onUpdate)
			this.syncSpeaker(show)
		} else {
			this.visible = false
		}
	}

	private syncSpeaker(showOnChange: boolean) {
		if (!this.speaker) return

		try {
			const volume = this.speaker.volume
			const mute = this.speaker.mute
			const icon = this.speaker.volumeIcon
			const changed =
				this.lastVolume !== volume ||
				this.lastMute !== mute ||
				this.lastIcon !== icon

			this.lastVolume = volume
			this.lastMute = mute
			this.lastIcon = icon

			if (changed) {
				this.volume = volume
				this.icon = icon
				if (showOnChange) this.show()
			}
		} catch (error) {
			console.error("Failed to read the default speaker state:", error)
		}
	}

	private show() {
		this.visible = true
		if (this.timeout) GLib.source_remove(this.timeout)
		this.timeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
			this.visible = false
			this.timeout = null
			return false
		})
	}

	destroy() {
		if (this.speaker) {
			if (this.volumeHandlerId) this.speaker.disconnect(this.volumeHandlerId)
			if (this.muteHandlerId) this.speaker.disconnect(this.muteHandlerId)
		}
		if (this.audio && this.defaultSpeakerHandlerId) {
			this.audio.disconnect(this.defaultSpeakerHandlerId)
			this.defaultSpeakerHandlerId = 0
		}
		if (this.timeout) GLib.source_remove(this.timeout)
		if (this.watchdogId) GLib.source_remove(this.watchdogId)
		this.timeout = null
		this.watchdogId = null
	}

	private onUpdate = () => {
		this.syncSpeaker(false)
		if (this.speaker) this.show()
	}
}

const osdState = new OSDState()

export function cleanup() {
	osdState.destroy()
}

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
