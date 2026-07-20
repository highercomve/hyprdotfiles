import nav from "./ControlPanelNav"
import { Astal, Gtk } from "ags/gtk4"
import App from "ags/gtk4/app"
import { createBinding } from "ags"
import AudioWidget, { DeviceList } from "./AudioWidget"
import NetworkWidget from "./NetworkWidget"
import BluetoothWidget from "./BluetoothWidget"
import NotificationList, { DNDSwitch } from "./NotificationWidget"
import PopupWindow from "./PopupWindow"
import Notifd from "gi://AstalNotifd"
import BrightnessService from "./BrightnessService"
import Network from "gi://AstalNetwork"
import Bluetooth from "gi://AstalBluetooth"

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
	icon: string | any
	label: string
	active?: boolean | any
	onClick?: () => void
	onDetail?: () => void
}) {
	const boxClass = typeof active === "boolean" || active === undefined
		? `toggle-pill ${active ? "active" : ""}`
		: active.as((a: boolean) => `toggle-pill ${a ? "active" : ""}`)

	const btnClass = typeof active === "boolean" || active === undefined
		? `toggle-icon ${active ? "active" : ""}`
		: active.as((a: boolean) => `toggle-icon ${a ? "active" : ""}`)

	return (
		<box class={boxClass} spacing={0}>
			<button
				class={btnClass}
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

function BrightnessSlider() {
	return (
		<box
			visible={createBinding(BrightnessService, "available")}
			orientation={Gtk.Orientation.VERTICAL}
			class="brightness-slider-container"
			spacing={8}
			marginTop={10}
			marginBottom={10}
		>
			<label
				label="Brightness"
				css="font-weight: bold; font-size: 1.1em;"
				xalign={0}
			/>
			<box spacing={8}>
				<Gtk.Image iconName="display-brightness-symbolic" />
				<Gtk.Scale
					hexpand
					adjustment={
						new Gtk.Adjustment({
							lower: 0,
							upper: 1,
							stepIncrement: 0.05,
							pageIncrement: 0.1,
						})
					}
					onChangeValue={(self, _, value) => {
						BrightnessService.screen_value = value
					}}
					$={(self) => {
						self.adjustment.value = BrightnessService.screen
						const id = BrightnessService.connect("notify::screen", () => {
							self.adjustment.value = BrightnessService.screen
						})
						self.connect("destroy", () => BrightnessService.disconnect(id))
					}}
				/>
			</box>
		</box>
	)
}

function ConnectivityToggles() {
	const net = Network.get_default()
	const bt = Bluetooth.get_default()

	const wifiActive = net?.wifi ? createBinding(net.wifi, "enabled") : false
	const wifiIcon = net?.wifi ? createBinding(net.wifi, "iconName") : "network-wireless-symbolic"

	const btActive = bt ? createBinding(bt, "isPowered") : false

	return (
		<box spacing={4} homogeneous>
			<TogglePill
				icon={wifiIcon}
				label="Wi-Fi"
				active={wifiActive}
				onClick={() => {
					if (net?.wifi) net.wifi.enabled = !net.wifi.enabled
				}}
				onDetail={() => (nav.page = "network")}
			/>
			<TogglePill
				icon="bluetooth-active-symbolic"
				label="Bluetooth"
				active={btActive}
				onClick={() => {
					if (bt?.adapter) bt.adapter.powered = !bt.adapter.powered
				}}
				onDetail={() => (nav.page = "bluetooth")}
			/>
		</box>
	)
}

function NotificationSection() {
	return (
		<box
			orientation={Gtk.Orientation.VERTICAL}
			spacing={8}
			css="margin-top: 12px;"
		>
			<box css="min-height: 1px; background-color: rgba(255,255,255,0.1); margin: 4px 0;" />
			<DNDSwitch />
			<Gtk.ScrolledWindow vexpand css="min-height: 200px;">
				<NotificationList />
			</Gtk.ScrolledWindow>
		</box>
	)
}

function MainPage() {
	return (
		<box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
			<ConnectivityToggles />
			<BrightnessSlider />
			<button onClicked={() => (nav.page = "audio")} css="padding: 6px;">
				<box spacing={8} halign={Gtk.Align.CENTER}>
					<Gtk.Image iconName="audio-card-symbolic" />
					<label label="Manage Audio Devices" />
					<Gtk.Image iconName="go-next-symbolic" />
				</box>
			</button>
			<AudioWidget />
			<NotificationSection />
		</box>
	) as Gtk.Box
}

function NetworkPage() {
	return (
		<box orientation={Gtk.Orientation.VERTICAL}>
			<PageHeader label="Wi-Fi" onBack={() => (nav.page = "main")} />
			<NetworkWidget />
		</box>
	) as Gtk.Box
}

function BluetoothPage() {
	return (
		<box orientation={Gtk.Orientation.VERTICAL}>
			<PageHeader label="Bluetooth" onBack={() => (nav.page = "main")} />
			<BluetoothWidget />
		</box>
	) as Gtk.Box
}

function AudioPage() {
	return (
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
}

export default function ControlPanel() {
	const notifd = Notifd.get_default()

	return (
		<PopupWindow
			name="control-panel"
			application={App}
			widthRequest={400} // Slightly wider
			heightRequest={800}
			marginRight={5}
			marginTop={40}
			halign={Gtk.Align.END}
			valign={Gtk.Align.START}
			layer={Astal.Layer.OVERLAY}
			keymode={Astal.Keymode.ON_DEMAND}
		>
			<box class="control-panel" css="padding: 30px 16px;">
				<Gtk.Stack
					transitionType={Gtk.StackTransitionType.SLIDE_LEFT_RIGHT}
					interpolateSize
					$={(self) => {
						self.add_named(<MainPage />, "main")
						self.add_named(<NetworkPage />, "network")
						self.add_named(<BluetoothPage />, "bluetooth")
						self.add_named(<AudioPage />, "audio")

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
