import { createPoll } from "ags/time"
import GLib from "gi://GLib"

export default function Clock({ format = "%H:%M - %a %d %b" }) {
	const time = createPoll(
		"",
		1000,
		() => GLib.DateTime.new_now_local().format(format)!,
	)

	return <label class="clock" label={time} />
}
