import { createBinding, For } from "ags"
import { Gtk } from "ags/gtk4"
import Tray from "gi://AstalTray"

function TrayItem({ item }: { item: Tray.TrayItem }) {
	return (
		<Gtk.MenuButton
			class="systray-item"
			visible={createBinding(item, "gicon").as((icon) => icon !== null)}
			tooltipMarkup={createBinding(item, "tooltipMarkup")}
			primary={createBinding(item, "isMenu")((isMenu) => !isMenu)}
			menuModel={createBinding(item, "menuModel")}
			$={(self) => {
				const updateGroup = () => {
					if (item.action_group) {
						self.insert_action_group("dbusmenu", item.action_group)
					}
				}
				updateGroup()
				const signalId = item.connect("notify::action-group", updateGroup)
				self.connect("destroy", () => item.disconnect(signalId))
			}}
			onActivate={() => item.activate(0, 0)}
		>
			<Gtk.Image gicon={createBinding(item, "gicon")} />
		</Gtk.MenuButton>
	)
}

export default function SysTray() {
	const tray = Tray.get_default()
	if (!tray) return <box visible={false} />

	const items = createBinding(tray, "items")

	return (
		<box class="systray" spacing={8}>
			<For each={items}>
				{(item) => <TrayItem item={item} />}
			</For>
		</box>
	)
}