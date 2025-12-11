import { createBinding, For } from "ags"
import { Gtk } from "ags/gtk4"
import Wp from "gi://AstalWp"
import Pango from "gi://Pango"

import nav from "./ControlPanelNav"

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

	// Speaker bindings
	const speakerVolume = createBinding(speaker, "volume")
	const speakerIcon = createBinding(speaker, "volumeIcon")
	const speakerDesc = createBinding(speaker, "description")

	// Mic bindings
	const micVolume = createBinding(mic, "volume")
	const micIcon = createBinding(mic, "volumeIcon")
	const micDesc = createBinding(mic, "description")

	return (
		<box
			orientation={Gtk.Orientation.VERTICAL}
			class="audio-widget"
			spacing={8}
			marginTop={20}
		>
			<label
				label="Audio"
				css="font-weight: bold; font-size: 1.1em;"
				xalign={0}
			/>

			{/* Speaker */}
			<box spacing={8}>
				<button onClicked={() => (speaker.mute = !speaker.mute)}>
					<Gtk.Image iconName={speakerIcon} />
				</button>
				<slider
					hexpand
					value={speakerVolume}
					onChangeValue={(_, __, value) => {
						speaker.volume = value
					}}
				/>
				<button onClicked={() => (nav.page = "audio")} css="padding: 0 8px;">
					<label
						label={speakerDesc.as((d) => d || "Speaker")}
						ellipsize={Pango.EllipsizeMode.END}
						maxWidthChars={15}
					/>
				</button>
			</box>

			{/* Mic */}
			<box spacing={8} css="margin-top: 8px;">
				<button onClicked={() => (mic.mute = !mic.mute)}>
					<Gtk.Image iconName={micIcon} />
				</button>
				<slider
					hexpand
					value={micVolume}
					onChangeValue={(_, __, value) => {
						mic.volume = value
					}}
				/>
				<button onClicked={() => (nav.page = "audio")} css="padding: 0 8px;">
					<label
						label={micDesc.as((d) => d || "Mic")}
						ellipsize={Pango.EllipsizeMode.END}
						maxWidthChars={15}
					/>
				</button>
			</box>
		</box>
	)
}
