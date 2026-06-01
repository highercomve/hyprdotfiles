import { createBinding, For } from "ags"
import Hyprland from "gi://AstalHyprland"
import { Gtk } from "ags/gtk4"

function substitute(className: string) {
	const subs: Record<string, string> = {
		"dev.zed.Zed": "zed",
	}
	return subs[className] || className
}

function makeClientSorter() {
	let cached: Hyprland.Client[] = []
	return (c: Hyprland.Client[]) => {
		const sorted = [...c].sort((a, b) => a.workspace.id - b.workspace.id)
		let identical = sorted.length === cached.length
		if (identical) {
			for (let i = 0; i < sorted.length; i++) {
				if (sorted[i] !== cached[i]) { identical = false; break }
			}
		}
		if (!identical) cached = sorted
		return cached
	}
}

export default function Taskbar() {
	const hypr = Hyprland.get_default()
	const getClients = makeClientSorter()

	// Sort clients by workspace ID to keep them ordered
	const clients = createBinding(hypr, "clients").as(getClients)

	return (
		<box class="taskbar">
			<For each={clients}>
				{(client) => (
					<button
						class="taskbar-item"
						tooltipText={createBinding(client, "title")}
						onClicked={() => client.focus()}
					>
						<Gtk.Image
							iconName={createBinding(client, "class").as(substitute)}
						/>
					</button>
				)}
			</For>
		</box>
	)
}
