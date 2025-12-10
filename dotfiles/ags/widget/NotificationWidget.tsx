import { createBinding, For } from "ags"
import { Gtk } from "ags/gtk4"
import Pango from "gi://Pango"
import Notifd from "gi://AstalNotifd"

function NotificationItem({ n }: { n: Notifd.Notification }) {
	const summary = createBinding(n, "summary")
	const body = createBinding(n, "body")
	const icon = createBinding(n, "appIcon")
	const image = createBinding(n, "image")

	return (
		<box
			class="notification-card"
			spacing={8}
			css="padding: 12px; background-color: rgba(255,255,255,0.05); border-radius: 12px; margin-bottom: 8px;"
		>
			{/* Icon / Image */}
			<box valign={Gtk.Align.START}>
				<Gtk.Image
					iconName={icon.as((i) => i || "dialog-information-symbolic")}
					pixelSize={32}
				/>
			</box>

			{/* Text Content */}
			<box orientation={Gtk.Orientation.VERTICAL} hexpand>
				<Gtk.Label
					label={summary}
					halign={Gtk.Align.START}
					ellipsize={Pango.EllipsizeMode.END}
					css="font-weight: bold;"
				/>
				<Gtk.Label
					label={body}
					halign={Gtk.Align.START}
					wrap
					useMarkup
					lines={2}
					ellipsize={Pango.EllipsizeMode.END}
					css="color: var(--subtext0); font-size: 0.9em;"
				/>
				<label
					label={createBinding(n, "time").as((t) => {
						const date = new Date(t * 1000)
						// Simple relative time or shorter format
						return date.toLocaleTimeString([], {
							hour: "2-digit",
							minute: "2-digit",
						})
					})}
					css="font-size: 0.7em; color: var(--overlay0); margin-top: 4px;"
					halign={Gtk.Align.END}
				/>
			</box>

			{/* Actions (Close) */}
			<button
				valign={Gtk.Align.START}
				css="padding: 4px; background: transparent;"
				onClicked={() => n.dismiss()}
			>
				<Gtk.Image iconName="window-close-symbolic" pixelSize={16} />
			</button>
		</box>
	)
}

export function DNDSwitch() {
	const notifd = Notifd.get_default()
	const dnd = createBinding(notifd, "dontDisturb")

	return (
		<box spacing={12} css="padding: 8px 12px;">
			<label
				label="Do not disturb"
				hexpand
				xalign={0}
				css="font-weight: 500;"
			/>
			<Gtk.Switch
				active={dnd}
				onStateSet={(_, state) => {
					notifd.dontDisturb = state
					return true
				}}
				valign={Gtk.Align.CENTER}
			/>
		</box>
	)
}

export default function NotificationList() {
	const notifd = Notifd.get_default()
	const notifications = createBinding(notifd, "notifications")

	return (
		<box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
			<box spacing={8} css="margin-bottom: 8px; padding: 0 4px;">
				<Gtk.Image
					iconName="preferences-system-notifications-symbolic"
					css="color: var(--subtext0);"
				/>
				<label
					label="Notifications"
					css="font-size: 0.9em; color: var(--subtext0);"
					hexpand
					xalign={0}
				/>
				<button
					visible={notifications.as((l) => l.length > 0)}
					css="padding: 4px 8px; font-size: 0.8em;"
					onClicked={() => notifd.notifications.forEach((n) => n.dismiss())}
				>
					<Gtk.Image iconName="user-trash-symbolic" pixelSize={14} />
				</button>
			</box>

			{/* Limit height or let it expand, ControlPanel sets scrolling if needed, but here we likely want standard flow */}
			<box orientation={Gtk.Orientation.VERTICAL}>
				<For each={notifications}>{(n) => <NotificationItem n={n} />}</For>
				<label
					visible={notifications.as((l) => l.length === 0)}
					label="No notifications"
					css="margin-top: 20px; margin-bottom: 20px; color: var(--overlay0);"
				/>
			</box>
		</box>
	)
}
