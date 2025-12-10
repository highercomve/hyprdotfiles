import { execAsync } from "ags/process"

export default function PowerMenu() {
	return (
		<button
			class="powermenu"
			onClicked={() => execAsync("bash -c '~/.config/hypr/scripts/wlogout.sh'")}
		>
			<image iconName="system-shutdown-symbolic" />
		</button>
	)
}
