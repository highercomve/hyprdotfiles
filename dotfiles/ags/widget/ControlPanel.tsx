import nav from "./ControlPanelNav"
import { Astal, Gtk } from "ags/gtk4"
import App from "ags/gtk4/app"
import AudioWidget, { DeviceList } from "./AudioWidget"
import NetworkWidget from "./NetworkWidget"
import BluetoothWidget from "./BluetoothWidget"
import NotificationList, { DNDSwitch } from "./NotificationWidget"
import PopupWindow from "./PopupWindow"
import Notifd from "gi://AstalNotifd"

function PageHeader({ label, onBack }: { label: string; onBack: () => void }) {
	return (
		<box spacing={8} css="margin-bottom: 12px;">
			<button onClicked={onBack}>
				<Gtk.Image iconName="go-previous-symbolic" />
			</button>
			<label
				label={label}
				css="font-weight: bold; font-size: 1.2em;"
				hexpand
				xalign={0.5}
			/>
			<box />
		</box>
	)
}

// Simple Main Page Toggles (Pill style)
function TogglePill({
	icon,
	label,
	active,
	onClick,
	onDetail,
}: {
	icon: string
	label: string
	active?: boolean
	onClick?: () => void
	onDetail?: () => void
}) {
	return (
		<box class={`toggle-pill ${active ? "active" : ""}`} spacing={0}>
			<button
				class={`toggle-icon ${active ? "active" : ""}`}
				onClicked={onClick}
				hexpand
			>
				<box spacing={8} halign={Gtk.Align.START}>
					<Gtk.Image iconName={icon} />
					<label label={label} css="font-weight: 500;" />
				</box>
			</button>
			<box css="min-width: 1px; background-color: rgba(255,255,255,0.1);" />
			<button class="toggle-arrow" onClicked={onDetail}>
				<Gtk.Image iconName="go-next-symbolic" />
			</button>
		</box>
	)
}

export default function ControlPanel() {
	const notifd = Notifd.get_default()

	const mainPage = (
		<box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
			{/* Toggles Grid */}
			<box spacing={4} homogeneous>
				<TogglePill
					icon="network-wireless-symbolic"
					label="Wi-Fi"
					active={true} // TODO: actual state
					onDetail={() => (nav.page = "network")}
				/>
				<TogglePill
					icon="bluetooth-active-symbolic"
					label="Bluetooth"
					active={true}
					onDetail={() => (nav.page = "bluetooth")}
				/>
			</box>

			{/* Media moved to separate popup */}

			<AudioWidget />

			{/* <box css="min-height: 1px; background-color: rgba(255,255,255,0.1); margin: 8px 0;" /> */}

			{/* <DNDSwitch />

            <Gtk.ScrolledWindow vexpand css="min-height: 200px;">
                <NotificationList />
            </Gtk.ScrolledWindow> */}
		</box>
	) as Gtk.Box

	const networkPage = (
		<box orientation={Gtk.Orientation.VERTICAL}>
			<PageHeader label="Wi-Fi" onBack={() => (nav.page = "main")} />
			<NetworkWidget />
		</box>
	) as Gtk.Box

	const bluetoothPage = (
		<box orientation={Gtk.Orientation.VERTICAL}>
			<PageHeader label="Bluetooth" onBack={() => (nav.page = "main")} />
			<BluetoothWidget />
		</box>
	) as Gtk.Box

	const audioPage = (
		<box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
			<PageHeader label="Audio Devices" onBack={() => (nav.page = "main")} />

			<label
				label="Output"
				css="font-weight: bold; margin-top: 4px;"
				xalign={0}
			/>
			<Gtk.ScrolledWindow vexpand>
				<DeviceList type="Audio" />
			</Gtk.ScrolledWindow>

			<label
				label="Input"
				css="font-weight: bold; margin-top: 12px;"
				xalign={0}
			/>
			<Gtk.ScrolledWindow vexpand>
				<DeviceList type="Microphone" />
			</Gtk.ScrolledWindow>
		</box>
	) as Gtk.Box

	return (
		<PopupWindow
			name="control-panel"
			application={App}
			widthRequest={400} // Slightly wider
			heightRequest={400}
			marginRight={12}
			marginTop={40}
			halign={Gtk.Align.END}
			valign={Gtk.Align.START}
			layer={Astal.Layer.OVERLAY}
			keymode={Astal.Keymode.ON_DEMAND}
		>
			<box class="control-panel" css="padding: 16px;">
				<Gtk.Stack
					transitionType={Gtk.StackTransitionType.SLIDE_LEFT_RIGHT}
					interpolateSize
					$={(self) => {
						self.add_named(mainPage, "main")
						self.add_named(networkPage, "network")
						self.add_named(bluetoothPage, "bluetooth")
						self.add_named(audioPage, "audio")

						// Standard GObject connection
						const id = nav.connect("notify::page", () => {
							self.set_visible_child_name(nav.page)
						})
						// Initial set
						self.set_visible_child_name(nav.page)

						// Cleanup
						self.connect("destroy", () => {
							nav.disconnect(id)
						})
					}}
				/>
			</box>
		</PopupWindow>
	)
}
