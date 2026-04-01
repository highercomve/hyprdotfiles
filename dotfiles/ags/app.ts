import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import ControlPanel from "./widget/ControlPanel"

import CenterPopup from "./widget/CenterPopup"
import OSD from "./widget/OSD"
import NotificationPopups from "./widget/NotificationPopups"

import youtubeService from "./widget/YouTubeService"
import brightnessService from "./widget/BrightnessService"
import { cleanup as cleanupSystemMonitor } from "./widget/SystemMonitor"
import { cleanup as cleanupTools } from "./widget/ToolsWidget"
import { cleanup as cleanupOSD } from "./widget/OSD"
import { cleanupNotificationPopups } from "./widget/NotificationPopups"

app.start({
	css: style,
	main() {
		const monitors = app.get_monitors()
		monitors.map(Bar)
		monitors.map(OSD)
		monitors.map(NotificationPopups)
		ControlPanel()
		CenterPopup()

		app.connect("shutdown", () => {
			youtubeService.destroy()
			brightnessService.destroy()
			cleanupSystemMonitor()
			cleanupTools()
			cleanupOSD()
			cleanupNotificationPopups()
		})
	},
})