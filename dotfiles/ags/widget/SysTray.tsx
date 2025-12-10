import { createBinding, For } from "ags"
import { Gtk } from "ags/gtk4"
import Tray from "gi://AstalTray"

export default function SysTray() {
	const tray = Tray.get_default()
	if (!tray) return <box visible={false} />

	const items = createBinding(tray, "items")

	return (
		<box class="systray" spacing={8}>
			<For each={items}>
				{(item) => (
					<button
						class="systray-item"
						tooltipMarkup={createBinding(item, "tooltipMarkup")}
						onClicked={() => item.activate(0, 0)}
					>
						<Gtk.Image gicon={createBinding(item, "gicon")} />
					</button>
				)}
			</For>
		</box>
	)
}
