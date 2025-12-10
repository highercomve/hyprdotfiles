import { createBinding, For } from "ags"
import Hyprland from "gi://AstalHyprland"
import { Gtk } from "ags/gtk4"

export default function Taskbar() {
	const hypr = Hyprland.get_default()

	// Sort clients by workspace ID to keep them ordered
	const clients = createBinding(hypr, "clients").as((c) =>
		[...c].sort((a, b) => a.workspace.id - b.workspace.id),
	)

	return (
		<box class="taskbar">
			<For each={clients}>
				{(client) => (
					<button
						class="taskbar-item"
						tooltipText={createBinding(client, "title")}
						onClicked={() => client.focus()}
					>
						<Gtk.Image iconName={createBinding(client, "class")} />
					</button>
				)}
			</For>
		</box>
	)
}
