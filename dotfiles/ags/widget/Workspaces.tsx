import { createBinding, For } from "ags"
import Hyprland from "gi://AstalHyprland"

export default function Workspaces() {
	const hypr = Hyprland.get_default()
	const workspaces = createBinding(hypr, "workspaces").as((ws) =>
		[...ws].sort((a, b) => a.id - b.id),
	)
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
