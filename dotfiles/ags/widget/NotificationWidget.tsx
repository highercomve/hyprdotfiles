import { createBinding, For } from "ags"
import { Gtk } from "ags/gtk4"
import Pango from "gi://Pango"
import Notifd from "gi://AstalNotifd"
import GLib from "gi://GLib"
import GObject, { register, property } from "ags/gobject"

@register({ GTypeName: "NotificationItemState" })
class NotificationItemState extends GObject.Object {
	@property(Boolean) expanded = false
}

export function NotificationItem({ n, isClosing }: { n: Notifd.Notification; isClosing?: boolean | any }) {
	const summary = createBinding(n, "summary")
	const body = createBinding(n, "body")
	const icon = createBinding(n, "appIcon")

	const state = new NotificationItemState()
	const expanded = createBinding(state, "expanded")

	const { START, CENTER, END } = Gtk.Align

	return (
		<Gtk.Revealer
			transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
			transitionDuration={300}
			$={(self) => {
				self.reveal_child = false
				// Trigger entry animation
				const id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 10, () => {
					self.reveal_child = true
					return false
				})
				self.connect("destroy", () => GLib.source_remove(id))
			}}
			// Logic for closing transition if binding is provided
			revealChild={isClosing ? isClosing.as((c: boolean) => !c) : true}
		// Wait, the entry animation works by starting false then true. 
		// If I bind revealChild, the manual 'true' set might be overridden if the binding emits.
		// Better strategy: Use a computed binding merging 'mounted' state and 'isClosing'.
		>
			<box
				class="notification-card"
				spacing={8}
			>
				{/* Icon / Image */}
				<box valign={START}>
					<Gtk.Image
						iconName={icon.as((i) => i || "dialog-information-symbolic")}
						pixelSize={32}
					/>
				</box>

				{/* Text Content - Click to Expand */}
				<button
					hexpand
					onClicked={() => { state.expanded = !state.expanded }}
					css="padding: 0; background: transparent; border: none; box-shadow: none;"
				>
					<box orientation={Gtk.Orientation.VERTICAL}>
						<Gtk.Label
							label={summary}
							halign={START}
							ellipsize={Pango.EllipsizeMode.END}
							css="font-weight: bold;"
						/>
						<Gtk.Label
							label={body}
							halign={START}
							wrap
							useMarkup
							lines={expanded.as(e => e ? -1 : 2)}
							ellipsize={expanded.as(e => e ? Pango.EllipsizeMode.NONE : Pango.EllipsizeMode.END)}
							css="color: var(--subtext0); font-size: 0.9em;"
						/>
						<label
							label={createBinding(n, "time").as((t) => {
								const date = new Date(t * 1000)
								return date.toLocaleTimeString([], {
									hour: "2-digit",
									minute: "2-digit",
								})
							})}
							css="font-size: 0.7em; color: var(--overlay0); margin-top: 4px;"
							halign={END}
						/>
					</box>
				</button>

				{/* Actions (Close) */}
				<button
					valign={START}
					css="padding: 4px; background: transparent; border: none; box-shadow: none;"
					onClicked={() => n.dismiss()}
				>
					<Gtk.Image iconName="window-close-symbolic" pixelSize={16} />
				</button>
			</box>
		</Gtk.Revealer>
	)
}

export function DNDSwitch() {
	const notifd = Notifd.get_default()
	const dnd = createBinding(notifd, "dontDisturb")
	const notifications = createBinding(notifd, "notifications")

	return (
		<box spacing={12} css="padding: 8px 12px;">
			<label
				label="Do not disturb"
				hexpand
				xalign={0}
				css="font-weight: 500;"
			/>
			<button
				visible={notifications.as((l) => l.length > 0)}
				css="padding: 4px 8px; font-size: 0.8em;"
				onClicked={() => notifd.notifications.forEach((n) => n.dismiss())}
			>
				<Gtk.Image iconName="user-trash-symbolic" pixelSize={14} />
			</button>
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
