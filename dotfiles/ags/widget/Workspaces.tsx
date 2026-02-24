import { createBinding, For } from "ags"
import Hyprland from "gi://AstalHyprland"

let cachedWorkspaces: Hyprland.Workspace[] = []
function getWorkspaces(ws: Hyprland.Workspace[]) {
	const sorted = [...ws].sort((a, b) => a.id - b.id)
	let changed = sorted.length !== cachedWorkspaces.length
	if (!changed) {
		for (let i = 0; i < sorted.length; i++) {
			if (sorted[i] !== cachedWorkspaces[i]) {
				changed = true
				break
			}
		}
	}
	if (changed) cachedWorkspaces = sorted
	return cachedWorkspaces
}

export default function Workspaces() {
	const hypr = Hyprland.get_default()
	const workspaces = createBinding(hypr, "workspaces").as(getWorkspaces)
	const focusedWorkspace = createBinding(hypr, "focusedWorkspace")

	return (
		<box class="workspaces">
			<For each={workspaces}>
				{(ws) => (
					<button
						class={focusedWorkspace((fw) => (ws === fw ? "active" : ""))}
						onClicked={() => ws.focus()}
					>
						{ws.id}
					</button>
				)}
			</For>
		</box>
	)
}
