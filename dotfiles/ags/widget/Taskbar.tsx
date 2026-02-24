import { createBinding, For } from "ags"
import Hyprland from "gi://AstalHyprland"
import { Gtk } from "ags/gtk4"

const hypr = Hyprland.get_default()

function substitute(className: string) {
	const subs: Record<string, string> = {
		"dev.zed.Zed": "zed",
	}
	return subs[className] || className
}

let cachedClients: Hyprland.Client[] = []
function getClients(c: Hyprland.Client[]) {
	const sorted = [...c].sort((a, b) => a.workspace.id - b.workspace.id)
	let changed = sorted.length !== cachedClients.length
	if (!changed) {
		for (let i = 0; i < sorted.length; i++) {
			if (sorted[i] !== cachedClients[i]) {
				changed = true
				break
			}
		}
	}
	if (changed) cachedClients = sorted
	return cachedClients
}

export default function Taskbar() {
	const hypr = Hyprland.get_default()

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
