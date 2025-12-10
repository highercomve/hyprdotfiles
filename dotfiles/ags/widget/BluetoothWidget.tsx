import { createBinding, For } from "ags"
import { Gtk } from "ags/gtk4"
import Bluetooth from "gi://AstalBluetooth"
import Pango from "gi://Pango"

export default function BluetoothWidget() {
	const bt = Bluetooth.get_default()
	if (!bt) return <label label="Bluetooth not found" />

	// Safety check just in case properties are missing
	const isPowered = createBinding(bt, "isPowered")
	const devices = createBinding(bt, "devices")
	const adapter = bt.adapter // might be null, usually accessible

	// Sort devices: Connected first
	const sortedDevices = devices.as((devs) =>
		[...devs].sort((a, b) => Number(b.connected) - Number(a.connected)),
	)

	return (
		<box
			orientation={Gtk.Orientation.VERTICAL}
			class="bluetooth-widget"
			spacing={8}
		>
			<box spacing={8}>
				<label
					label="Bluetooth"
					hexpand
					xalign={0}
					css="font-weight: bold; font-size: 1.1em;"
				/>

				{adapter && (
					<button
						tooltipText={createBinding(adapter, "discovering").as((d) =>
							d ? "Stop Discovery" : "Scan for Devices",
						)}
						onClicked={() => {
							if (adapter.discovering) adapter.stop_discovery()
							else adapter.start_discovery()
						}}
					>
						<Gtk.Image
							iconName={createBinding(adapter, "discovering").as((d) =>
								d ? "process-working-symbolic" : "system-search-symbolic",
							)}
						/>
					</button>
				)}

				<switch
					active={isPowered}
					onActivate={({ active }) => {
						bt.adapter.powered = active
					}}
				/>
			</box>

			<Gtk.ScrolledWindow
				hscrollbarPolicy={Gtk.PolicyType.NEVER}
				vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
				vexpand={true}
			>
				<box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
					<For each={sortedDevices}>
						{(dev) => {
							const connected = createBinding(dev, "connected")
							const icon = createBinding(dev, "icon")
							const alias = createBinding(dev, "alias")

							return (
								<button
									onClicked={() => {
										if (dev.connected) {
											// @ts-ignore: GJS require callback argument
											dev.disconnect_device(null)
										} else {
											if (!dev.paired) dev.pair()
											// @ts-ignore: GJS require callback argument
											dev.connect_device(null)
										}
									}}
									class={connected((c) => (c ? "active-network" : ""))}
								>
									<box spacing={8}>
										<Gtk.Image
											iconName={icon.as(
												(i) => i || "bluetooth-active-symbolic",
											)}
										/>
										<Gtk.Label
											label={alias((a) => a || dev.name || "Unknown")}
											xalign={0}
											hexpand
											ellipsize={Pango.EllipsizeMode.END}
										/>
										<Gtk.Image
											iconName="object-select-symbolic"
											visible={connected((c) => c)}
										/>
									</box>
								</button>
							)
						}}
					</For>
				</box>
			</Gtk.ScrolledWindow>
		</box>
	)
}
