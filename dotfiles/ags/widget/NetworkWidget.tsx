import { createBinding, For } from "ags"
import GObject, { register, property } from "ags/gobject"
import { Gtk } from "ags/gtk4"
import Network from "gi://AstalNetwork"
import NM from "gi://NM"
import Gio from "gi://Gio"

// Helper to run commands
function runCmd(argv: string[]) {
	try {
		Gio.Subprocess.new(argv, Gio.SubprocessFlags.NONE)
	} catch (e) {
		console.error(e)
	}
}

// Build a deduplicator with its own cache so the widget can drop it on destroy
// — module-level state would otherwise hold AP GObject references after the
// widget unmounts.
function makeApDeduplicator() {
	let cachedResult: Network.AccessPoint[] = []
	let lastApUpdate = 0

	return (aps: Network.AccessPoint[]) => {
		const map = new Map<string, Network.AccessPoint>()
		for (const ap of aps) {
			if (!ap.ssid) continue
			const existing = map.get(ap.ssid)
			if (!existing || ap.strength > existing.strength) {
				map.set(ap.ssid, ap)
			}
		}

		const result = Array.from(map.values()).sort((a, b) => b.strength - a.strength)

		let identical = result.length === cachedResult.length
		if (identical) {
			for (let i = 0; i < result.length; i++) {
				if (result[i] !== cachedResult[i]) { identical = false; break }
			}
		}
		if (identical) return cachedResult

		// Throttle binding updates when only ordering/strength shifted (same set of
		// APs by identity), but always swap to release stale AP references.
		const now = Date.now()
		const sameSet = result.length === cachedResult.length &&
			result.every(ap => cachedResult.includes(ap))
		if (sameSet && now - lastApUpdate < 3000) return cachedResult

		cachedResult = result
		lastApUpdate = now
		return cachedResult
	}
}

@register({ GTypeName: "NetworkViewState" })
class NetworkViewState extends GObject.Object {
	@property(String)
	view: string = "main"

	@property(String)
	confirming_uuid: string = ""
}

const viewState = new NetworkViewState()

function APItem({ ap, wifi, client }: { ap: Network.AccessPoint, wifi: Network.Wifi, client: NM.Client }) {
	const ssid = createBinding(ap, "ssid")
	const iconName = createBinding(ap, "iconName")
	const isActive = createBinding(wifi, "activeAccessPoint").as(
		(aap) => aap === ap,
	)
	const flags = createBinding(ap, "flags")

	// Check if this AP is a known connection
	const isKnown = createBinding(client, "connections").as((list) =>
		Boolean(
			list.find(
				(c) =>
					c.get_id() === ap.ssid &&
					c.get_connection_type() === "802-11-wireless",
			),
		),
	)

	const isConfirming = createBinding(viewState, "confirming_uuid").as(uuid => {
		// Find the connection UUID for this SSID to compare
		const conn = client.connections.find(
			(c) =>
				c.get_id() === ap.ssid &&
				c.get_connection_type() === "802-11-wireless",
		)
		return conn?.get_uuid() === uuid
	})

	return (
		<box spacing={4}>
			<button
				hexpand
				class={isActive((a) => (a ? "active-network" : ""))}
				onClicked={() => {
					if (wifi.activeAccessPoint !== ap) {
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
				</box>
			</button>
			<button
				tooltipText="Forget Network"
				visible={isKnown.as(k => k && viewState.confirming_uuid === "")}
				onClicked={() => {
					const conn = client.connections.find(
						(c) =>
							c.get_id() === ap.ssid &&
							c.get_connection_type() === "802-11-wireless",
					)
					if (conn) viewState.confirming_uuid = conn.get_uuid() || ""
				}}
				css="padding: 2px 8px;"
			>
				<Gtk.Image iconName="user-trash-symbolic" css="color: var(--red);" />
			</button>

			<button
				tooltipText="Confirm Delete"
				visible={isConfirming}
				onClicked={() => {
					const conn = client.connections.find(
						(c) =>
							c.get_id() === ap.ssid &&
							c.get_connection_type() === "802-11-wireless",
					)
					if (conn) {
						conn.delete_async(null, null)
						viewState.confirming_uuid = ""
					}
				}}
				css="padding: 2px 8px; border: 1px solid var(--red); margin-right: 4px;"
			>
				<Gtk.Image iconName="object-select-symbolic" css="color: var(--red);" />
			</button>

			<button
				tooltipText="Cancel"
				visible={isConfirming}
				onClicked={() => {
					viewState.confirming_uuid = ""
				}}
				css="padding: 2px 8px;"
			>
				<Gtk.Image iconName="process-stop-symbolic" />
			</button>
			<Gtk.Image
				iconName="object-select-symbolic"
				visible={isActive((a) => !!a)}
			/>
			<Gtk.Image
				iconName="channel-secure-symbolic"
				css="font-size: 12px; color: var(--subtext0);"
				visible={flags((f) =>
					Boolean(f & (NM as any)["80211ApFlags"].PRIVACY),
				)}
			/>
		</box>
	)
}

function SavedNetworkItem({ connection }: { connection: NM.RemoteConnection }) {
	const isConfirming = createBinding(viewState, "confirming_uuid").as(uuid => uuid === connection.get_uuid())

	return (
		<box spacing={8} css="padding: 8px; border-bottom: 1px solid rgba(255,255,255,0.05);">
			<Gtk.Image iconName="network-wireless-symbolic" css="color: var(--subtext0);" />
			<label
				label={connection.get_id() || "Unknown"}
				hexpand
				xalign={0}
				ellipsize={3}
			/>
			<button
				tooltipText="Forget Network"
				visible={isConfirming.as(c => !c)}
				onClicked={() => {
					viewState.confirming_uuid = connection.get_uuid() || ""
				}}
				css="padding: 4px 8px;"
			>
				<Gtk.Image iconName="user-trash-symbolic" css="color: var(--red);" />
			</button>

			<button
				tooltipText="Confirm Delete"
				visible={isConfirming}
				onClicked={() => {
					connection.delete_async(null, null)
					viewState.confirming_uuid = ""
				}}
				css="padding: 4px 8px; border: 1px solid var(--red); margin-right: 4px;"
			>
				<Gtk.Image iconName="object-select-symbolic" css="color: var(--red);" />
			</button>

			<button
				tooltipText="Cancel"
				visible={isConfirming}
				onClicked={() => {
					viewState.confirming_uuid = ""
				}}
				css="padding: 4px 8px;"
			>
				<Gtk.Image iconName="process-stop-symbolic" />
			</button>
		</box>
	)
}

export default function NetworkWidget() {
	const net = Network.get_default()
	if (!net) return <label label="Network service unavailable" />

	const wifi = net?.wifi
	const wired = net?.wired
	const client = net.client
	if (!client) return <label label="Network client unavailable" />

	// Wired Icon: Derive from state directly to ensure visibility
	const wiredIcon = wired ? createBinding(wired, "state").as((s) => {
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
	}) : "network-wired-symbolic"
	// Wired usually doesn't have an "enabled" prop like wifi.
	// We can infer state from internet/state.

	// Sort and Dedupe APs — per-widget cache so refs are released with the widget
	const deduplicateAPs = makeApDeduplicator()
	const sortedAPs = wifi
		? createBinding(wifi, "accessPoints").as(deduplicateAPs)
		: undefined

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
							runCmd([
								"nmcli",
								"device",
								active ? "connect" : "disconnect",
								dev.interface,
							])
						}}
					/>
				</box>
			)}

			{wired && (
				<box css="min-height: 1px; background-color: rgba(255,255,255,0.1); margin-bottom: 8px;" />
			)}

			{/* Main View */}
			<box visible={createBinding(viewState, "view").as((v) => v === "main")} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
				{wifi && (
					<box spacing={8}>
						<label
							label="Wi-Fi"
							hexpand
							xalign={0}
							css="font-weight: bold; font-size: 1.1em;"
						/>

						{/* Scan Button */}
						<button 
							tooltipText="Scan Networks" 
							onClicked={() => {
								try { wifi.scan() } catch (e) { console.error(e) }
							}}
							sensitive={createBinding(wifi, "scanning").as(s => !s)}
						>
							<Gtk.Image iconName={createBinding(wifi, "scanning").as(s => s ? "process-working-symbolic" : "system-search-symbolic")} />
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
						minContentHeight={200}
					>
						<box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
							<For each={sortedAPs!}>
								{(ap: Network.AccessPoint) => (
									<APItem ap={ap} wifi={wifi} client={client} />
								)}
							</For>
						</box>
					</Gtk.ScrolledWindow>
				)}

				{!wifi && <label label="Wi-Fi Unavailable" />}

				{/* Button to Saved Networks Page */}
				<button
					onClicked={() => (viewState.view = "saved")}
					css="padding: 8px;"
				>
					<box spacing={8} halign={Gtk.Align.CENTER}>
						<label label="Manage Saved Networks" css="font-weight: bold;" />
						<Gtk.Image iconName="go-next-symbolic" />
					</box>
				</button>
			</box>

			{/* Saved Networks View */}
			<box visible={createBinding(viewState, "view").as((v) => v === "saved")} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
				<box spacing={8}>
					<button onClicked={() => (viewState.view = "main")}>
						<Gtk.Image iconName="go-previous-symbolic" />
					</button>
					<label label="Saved Networks" css="font-weight: bold; font-size: 1.2em;" />
				</box>

				<Gtk.ScrolledWindow
					hscrollbarPolicy={Gtk.PolicyType.NEVER}
					vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
					vexpand={true}
				>
					<box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
						<For
							each={createBinding(client, "connections").as((connections) =>
								connections
									.filter((c) => c.get_connection_type() === "802-11-wireless")
									.sort((a, b) => (a.get_id() || "").localeCompare(b.get_id() || ""))
							)}
						>
							{(connection: NM.RemoteConnection) => (
								<SavedNetworkItem connection={connection} />
							)}
						</For>
					</box>
				</Gtk.ScrolledWindow>
			</box>
		</box>
	)
}
