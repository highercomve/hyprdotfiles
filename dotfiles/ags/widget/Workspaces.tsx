import { createBinding, For } from "ags"
import Hyprland from "gi://AstalHyprland"

function makeWorkspaceSorter() {
	let cached: Hyprland.Workspace[] = []
	return (ws: Hyprland.Workspace[]) => {
		const sorted = [...ws].sort((a, b) => a.id - b.id)
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

export default function Workspaces() {
	const hypr = Hyprland.get_default()
	const getWorkspaces = makeWorkspaceSorter()
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
