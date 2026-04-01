import App from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import GLib from "gi://GLib"
import Workspaces from "./Workspaces"
import ClientTitle from "./ClientTitle"
import Clock from "./Clock"
import { MediaBar } from "./Media"
import SysTray from "./SysTray"
import PowerMenu from "./PowerMenu"
import Audio from "gi://AstalWp"
import Battery from "gi://AstalBattery"
import Network from "gi://AstalNetwork"
import Bluetooth from "gi://AstalBluetooth"
import { createBinding } from "ags"
import ToolsRow from "./ToolsWidget"
import SystemMonitor from "./SystemMonitor"
import Taskbar from "./Taskbar"

function BatteryLevel() {
	const bat = Battery.get_default()

	if (!bat || !bat.isPresent) return <box visible={false} />

	return (
		<box class="battery-level" spacing={4}>
			<label
				class="battery-percentage"
				label={createBinding(bat, "percentage").as((p) =>
					Math.round(p * 100).toString() + "%",
				)}
			/>
			<Gtk.Image
				iconName={createBinding(bat, "iconName")}
				tooltipText={createBinding(bat, "state").as(
					(s) => `Battery: ${Math.round(bat.percentage * 100)}% [${s}]`,
				)}
			/>
		</box>
	)
}

import Notifd from "gi://AstalNotifd"

function QuickSettings() {
	const audio = Audio.get_default()?.audio.defaultSpeaker
	const notifd = Notifd.get_default()
	// const wifi = Network.get_default()?.wifi
	// const bt = Bluetooth.get_default()

	// Bindings might be null if service not available
	const volumeIcon = audio && createBinding(audio, "volumeIcon")
	const dndIcon = createBinding(notifd, "dontDisturb").as(dnd =>
		dnd ? "notifications-disabled-symbolic" : "preferences-system-notifications-symbolic"
	)

	return (
		<button
			class="quicksettings"
			onClicked={() => App.toggle_window("control-panel")}
			tooltipText="Quick Settings"
		>
			<box spacing={8}>
				<Gtk.Image iconName={dndIcon} />
				{volumeIcon && <Gtk.Image iconName={volumeIcon} />}
				{/* {wifiIcon && <Gtk.Image iconName={wifiIcon} />}
				{btPowered && (
					<Gtk.Image
						iconName={btPowered((p) =>
							p ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic",
						)}
					/>
				)}*/}
			</box>
		</button>
	)
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
	const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

	return (
		<Astal.Window
			name="bar"
			class="Bar"
			gdkmonitor={gdkmonitor}
			exclusivity={Astal.Exclusivity.EXCLUSIVE}
			anchor={TOP | LEFT | RIGHT}
			application={App}
			visible={true}
		>
			<Gtk.CenterBox class="BarCenterBox">
				<Gtk.Box hexpand halign={Gtk.Align.START} spacing={4} $type="start">
					<Workspaces />
					<Taskbar />
					<ClientTitle />
				</Gtk.Box>
				<Gtk.Box $type="center">
					<box class="group-center module-group" spacing={8}>
						<box css="min-width: 180px;" halign={Gtk.Align.CENTER}>
							<button
								onClicked={() => App.toggle_window("center-popup")}
								class="clock-button"
								css="background: transparent; border: none; padding: 0;"
							>
								<Clock />
							</button>
						</box>
						<box css="min-width: 1px; background-color: rgba(255,255,255,0.2);" />
						<box css="min-width: 180px;" halign={Gtk.Align.CENTER}>
							<MediaBar />
						</box>
					</box>
				</Gtk.Box>
				<Gtk.Box hexpand halign={Gtk.Align.END} spacing={0} $type="end">
					<SystemMonitor />
					<ToolsRow />
					{/* Add here a notification icon that open the swaync window */}
					<Gtk.Box class="group-system">
						<BatteryLevel />
						<SysTray />
						<QuickSettings />
						<PowerMenu />
					</Gtk.Box>
				</Gtk.Box>
			</Gtk.CenterBox>
		</Astal.Window>
	)
}

function NotificationButton() {
	return (
		<button
			class="notification-icon"
			onClicked={() =>
				GLib.spawn_command_line_async("swaync-client -t")
			}
			tooltipText="Notifications"
		>
			<Gtk.Image iconName="preferences-system-notifications-symbolic" />
		</button>
	) as Gtk.Button
}