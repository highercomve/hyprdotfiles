import { createBinding, For } from "ags"
import { Gtk } from "ags/gtk4"
import Wp from "gi://AstalWp"
import Pango from "gi://Pango"
import GObject, { register, property } from "ags/gobject"

@register({ GTypeName: "AudioWidgetState" })
class AudioWidgetState extends GObject.Object {
	@property(Boolean) showSpeaker = false
	@property(Boolean) showMic = false
}

function AudioEndpoint({
	device,
	label,
	state,
	expandedProperty,
}: {
	device: any
	label: string
	state: AudioWidgetState
	expandedProperty: "showSpeaker" | "showMic"
}) {
	const volume = createBinding(device, "volume")
	const icon = createBinding(device, "volumeIcon")
	const description = createBinding(device, "description")
	const expanded = createBinding(state, expandedProperty)

	return (
		<box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
			<box spacing={8}>
				<button onClicked={() => (device.mute = !device.mute)}>
					<Gtk.Image iconName={icon} />
				</button>
				<slider
					hexpand
					value={volume}
					onChangeValue={(_, __, value) => {
						device.volume = value
					}}
				/>
				<button
					onClicked={() => (state[expandedProperty] = !state[expandedProperty])}
					css="padding: 0 8px;"
				>
					<box spacing={4}>
						<label
							label={description.as((d) => d || label)}
							ellipsize={Pango.EllipsizeMode.END}
							maxWidthChars={15}
						/>
						<Gtk.Image
							iconName={expanded.as((open) =>
								open ? "pan-down-symbolic" : "pan-end-symbolic",
							)}
						/>
					</box>
				</button>
			</box>
			<Gtk.Revealer
				revealChild={expanded}
				transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
			>
				<box css="padding: 8px 0; border-top: 1px solid rgba(255,255,255,0.05);">
					<DeviceList type={label === "Mic" ? "Microphone" : "Audio"} />
				</box>
			</Gtk.Revealer>
		</box>
	)
}

export function DeviceList({
	type,
}: {
	type: "Audio" | "Video" | "Microphone"
}) {
	const wp = Wp.get_default()
	const audio = wp?.audio
	if (!audio) return <box />

	// Note: Assuming 'devices' is a list/array that is observable or re-emits on change?
	// Astal collections are often observable. createBinding might work on the property that holds the array.
	const devList = createBinding(
		audio,
		type === "Microphone" ? "microphones" : "speakers",
	)

	return (
		<box orientation={Gtk.Orientation.VERTICAL} spacing={4} class="device-list">
			<For each={devList}>
				{(dev) => {
					const isDefault = createBinding(dev, "isDefault")
					const description = createBinding(dev, "description")
					return (
						<button
							onClicked={() => dev.set_is_default(true)}
							class={isDefault((d) => (d ? "active-device" : ""))}
							css="padding: 8px 0;"
						>
							<box>
								<Gtk.Label
									label={description}
									hexpand
									xalign={0}
									ellipsize={Pango.EllipsizeMode.END}
								/>
								<Gtk.Image
									iconName="object-select-symbolic"
									visible={isDefault}
								/>
							</box>
						</button>
					)
				}}
			</For>
		</box>
	)
}

export default function AudioWidget() {
	const wp = Wp.get_default()
	if (!wp) return <label label="WirePlumber not found" />

	const speaker = wp.audio.defaultSpeaker
	const mic = wp.audio.defaultMicrophone

	const state = new AudioWidgetState()

	return (
		<box
			orientation={Gtk.Orientation.VERTICAL}
			class="audio-widget"
			spacing={8}
			marginTop={20}
			$={(self) => {
				self.connect("destroy", () => state.run_dispose())
			}}
		>
			<label
				label="Audio"
				css="font-weight: bold; font-size: 1.1em;"
				xalign={0}
			/>

			{speaker ? (
				<AudioEndpoint
					device={speaker}
					label="Speaker"
					state={state}
					expandedProperty="showSpeaker"
				/>
			) : <label label="No output device" />}

			{mic ? (
				<AudioEndpoint
					device={mic}
					label="Mic"
					state={state}
					expandedProperty="showMic"
				/>
			) : <label label="No input device" />}
		</box>
	)
}
