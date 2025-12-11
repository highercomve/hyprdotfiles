import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import ControlPanel from "./widget/ControlPanel"

import CenterPopup from "./widget/CenterPopup"
import OSD from "./widget/OSD"
import NotificationPopups from "./widget/NotificationPopups"

app.start({
	css: style,
	main() {
		const monitors = app.get_monitors()
		monitors.map(Bar)
		monitors.map(OSD)
		monitors.map(NotificationPopups)
		ControlPanel()
		CenterPopup()
	},
})
