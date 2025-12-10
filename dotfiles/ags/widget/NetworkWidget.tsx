import { createBinding, For } from "ags"
import { Gtk } from "ags/gtk4"
import Network from "gi://AstalNetwork"
import NM from "gi://NM"
import GLib from "gi://GLib"

// Helper to run commands
function runCmd(cmd: string) {
	try {
		GLib.spawn_command_line_async(cmd)
	} catch (e) {
		console.error(e)
	}
}

// Helper to deduplicate APs
function deduplicateAPs(aps: any[]) {
	const map = new Map<string, any>()
	aps.forEach((ap) => {
		if (!ap.ssid) return // Ignore hidden/unknown SSIDs for cleanliness, or handle nicely
		const existing = map.get(ap.ssid)
		if (!existing || ap.strength > existing.strength) {
			map.set(ap.ssid, ap)
		}
	})
	return Array.from(map.values()).sort((a, b) => b.strength - a.strength)
}

export default function NetworkWidget() {
	const net = Network.get_default()
	const wifi = net?.wifi
	const wired = net?.wired

	// Wired Icon: Derive from state directly to ensure visibility
	const wiredIcon = createBinding(wired, "state").as((s) => {
		switch (s) {
			case NM.DeviceState.ACTIVATED:
				return "network-wired-symbolic"
			case NM.DeviceState.DISCONNECTED:
				return "network-wired-disconnected-symbolic"
			case NM.DeviceState.UNAVAILABLE:
				return "network-wired-disconnected-symbolic"
			case NM.DeviceState.IP_CONFIG:
			case NM.DeviceState.IP_CHECK:
				return "network-wired-acquire-symbolic"
			default:
				return "network-wired-symbolic"
		}
	})
	// Wired usually doesn't have an "enabled" prop like wifi.
	// We can infer state from internet/state.

	// Sort and Dedupe APs
	const sortedAPs = wifi
		? createBinding(wifi, "accessPoints").as(deduplicateAPs)
		: []

	return (
		<box
			orientation={Gtk.Orientation.VERTICAL}
			class="network-widget"
			spacing={8}
		>
			{/* Wired Section */}
			{wired && (
				<box spacing={8} css="margin-bottom: 8px;">
					<Gtk.Image iconName={wiredIcon} />
					<label
						label="Ethernet"
						hexpand
						xalign={0}
						css="font-weight: bold; font-size: 1.1em;"
					/>
					<switch
						active={createBinding(wired, "state").as(
							(s) => s === NM.DeviceState.ACTIVATED,
						)}
						onActivate={({ active }) => {
							const dev = wired.device
							if (!dev) return
							const cmd = active
								? `nmcli device connect ${dev.interface}`
								: `nmcli device disconnect ${dev.interface}`
							runCmd(cmd)
						}}
					/>
				</box>
			)}

			{wired && (
				<box css="min-height: 1px; background-color: rgba(255,255,255,0.1); margin-bottom: 8px;" />
			)}

			{wifi && (
				<box spacing={8}>
					<label
						label="Wi-Fi"
						hexpand
						xalign={0}
						css="font-weight: bold; font-size: 1.1em;"
					/>

					{/* Scan Button */}
					<button tooltipText="Scan Networks" onClicked={() => wifi.scan()}>
						<Gtk.Image iconName="system-search-symbolic" />
					</button>

					<switch
						active={createBinding(wifi, "enabled")}
						onActivate={({ active }) => {
							wifi.enabled = active
						}}
					/>
				</box>
			)}

			{wifi && (
				<Gtk.ScrolledWindow
					hscrollbarPolicy={Gtk.PolicyType.NEVER}
					vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
					vexpand={true}
				>
					<box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
						<For each={sortedAPs}>
							{(ap: any) => {
								const ssid = createBinding(ap, "ssid")
								// ... existing binding logic ...
								const iconName = createBinding(ap, "iconName")
								const isActive = createBinding(wifi, "activeAccessPoint").as(
									(aap) => aap === ap,
								)
								const flags = createBinding(ap, "flags")

								return (
									<button
										class={isActive((a) => (a ? "active-network" : ""))}
										onClicked={() => {
											if (wifi.activeAccessPoint !== ap) {
												// Astal/NM AccessPoint.activate requires connection and specific object usually.
												// Passing null, null seems to be what GJS expects if not using a specific connection profile.
												// @ts-ignore
												ap.activate(null, null)
											}
										}}
									>
										<box spacing={8}>
											<Gtk.Image
												iconName={iconName.as(
													(i) =>
														i || "network-wireless-signal-unknown-symbolic",
												)}
											/>
											<Gtk.Label
												label={ssid((s: string) => s || "Unknown")}
												xalign={0}
												hexpand
												ellipsize={3}
											/>

											<Gtk.Image
												iconName="channel-secure-symbolic"
												css="font-size: 12px; color: var(--subtext0);"
												visible={flags((f) =>
													Boolean(f & (NM as any)["80211ApFlags"].PRIVACY),
												)}
											/>

											<Gtk.Image
												iconName="object-select-symbolic"
												visible={isActive((a) => !!a)}
											/>
										</box>
									</button>
								)
							}}
						</For>
					</box>
				</Gtk.ScrolledWindow>
			)}

			{!wifi && <label label="Wi-Fi Unavailable" />}
		</box>
	)
}
