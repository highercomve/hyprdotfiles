import { Astal, Gtk } from "ags/gtk4"
import App from "ags/gtk4/app"
import PopupWindow from "./PopupWindow"
import Media from "./Media"
import WorldClock from "./WorldClock"

export default function CenterPopup() {
	return (
		<PopupWindow
			name="center-popup"
			application={App}
			halign={Gtk.Align.CENTER}
			valign={Gtk.Align.START}
			marginTop={40}
			widthRequest={800}
			layer={Astal.Layer.OVERLAY}
		>
			<box
				class="center-popup-window"
				orientation={Gtk.Orientation.HORIZONTAL}
				spacing={20}
				css="padding: 24px;"
			>
				<box
                    class="calendar-container"
                    css="min-width: 370px;"
                    valign={Gtk.Align.START}
                    vexpand={false}
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={12}
                >
					<Gtk.Calendar />
                    {/* YouTube search hidden for now per user request */}
                    <WorldClock />
				</box>

				<box css="min-width: 1px; background-color: rgba(255,255,255,0.1); margin: 10px 0;" />

				<box class="media-container" css="min-width: 370px;">
					<Media />
				</box>
			</box>
		</PopupWindow>
	)
}