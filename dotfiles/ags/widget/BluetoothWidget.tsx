import { createBinding, For } from "ags"
import { Gtk } from "ags/gtk4"
import Bluetooth from "gi://AstalBluetooth"
import Pango from "gi://Pango"
import GLib from "gi://GLib"

export default function BluetoothWidget() {
	const bt = Bluetooth.get_default()
	if (!bt) return <label label="Bluetooth not found" />

	// Safety check just in case properties are missing
	const isPowered = createBinding(bt, "isPowered")
	const devices = createBinding(bt, "devices")
	const adapter = bt.adapter // might be null, usually accessible

	// Track discovery timeout to prevent leaks on rapid scan clicks
	let discoveryTimeoutId: number | null = null

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
							else {
								adapter.start_discovery()
								// Clear any previous discovery timeout to prevent stacking
								if (discoveryTimeoutId) {
									GLib.source_remove(discoveryTimeoutId)
								}
								discoveryTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 15000, () => {
									if (bt.adapter && bt.adapter.discovering) {
										bt.adapter.stop_discovery()
									}
									discoveryTimeoutId = null
									return GLib.SOURCE_REMOVE
								})
							}
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
						if (bt.adapter) {
							bt.adapter.powered = active
						}
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
											try {
												dev.disconnect_device(() => { })
											} catch (e) { console.error(e) }
										} else {
											try {
												if (!dev.paired) dev.pair()
												dev.connect_device(() => { })
											} catch (e) { console.error(e) }
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
										<Gtk.Label
											visible={createBinding(dev, "batteryPercentage").as((p) => p > 0)}
											label={createBinding(dev, "batteryPercentage").as((p) => `${Math.round(p * 100)}%`)}
											class="battery-level"
											css="color: var(--subtext0); font-size: 0.8em;"
										/>
										<Gtk.Image
											visible={createBinding(dev, "batteryPercentage").as((p) => p > 0)}
											iconName={createBinding(dev, "batteryPercentage").as((p) => {
												const val = Math.round(p * 100)
												if (val <= 10) return "battery-level-10-symbolic"
												if (val <= 20) return "battery-level-20-symbolic"
												if (val <= 30) return "battery-level-30-symbolic"
												if (val <= 40) return "battery-level-40-symbolic"
												if (val <= 50) return "battery-level-50-symbolic"
												if (val <= 60) return "battery-level-60-symbolic"
												if (val <= 70) return "battery-level-70-symbolic"
												if (val <= 80) return "battery-level-80-symbolic"
												if (val <= 90) return "battery-level-90-symbolic"
												return "battery-level-100-symbolic"
											})}
											css="color: var(--subtext0); margin-left: 2px;"
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
