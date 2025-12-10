import { createBinding } from "ags"
import Hyprland from "gi://AstalHyprland"
import Pango from "gi://Pango"

export default function ClientTitle() {
	const hypr = Hyprland.get_default()
	const focusedClient = createBinding(hypr, "focusedClient")

	return (
		<label
			class="client-title"
			ellipsize={Pango.EllipsizeMode.END}
			label={focusedClient((c) => (c ? c.title : ""))}
		/>
	)
}
