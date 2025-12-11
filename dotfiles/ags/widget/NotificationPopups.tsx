import { Astal, Gtk, Gdk } from "ags/gtk4"
import Notifd from "gi://AstalNotifd"
import GObject, { register, property } from "ags/gobject"
import { createBinding, For } from "ags"
import GLib from "gi://GLib"
import App from "ags/gtk4/app"
import { NotificationItem } from "./NotificationWidget"

const TIMEOUT = 5000 // 5 seconds
const TRANSITION_DURATION = 300 // ms

@register({ GTypeName: "PopupState" })
class PopupState extends GObject.Object {
    @property(Boolean) closing = false
}

interface PopupItem {
    n: Notifd.Notification
    id: number
    state: PopupState
}

@register({ GTypeName: "PopupManager" })
class PopupManager extends GObject.Object {
    private _popups: PopupItem[] = []

    // Using a counter to signal updates because @property(Object) for arrays can be buggy
    @property(Number) update = 0

    get popups() { return this._popups }

    set popups(v: PopupItem[]) {
        this._popups = v
        this.update++
        this.notify("update")
    }

    private map: Map<number, number> = new Map() // id -> timeoutId

    constructor() {
        super()
        const notifd = Notifd.get_default()

        notifd.connect("notified", (_, id) => {
            if (notifd.dontDisturb) return

            const n = notifd.get_notification(id)
            if (n) {
                this.add(n)
            }
        })

        notifd.connect("resolved", (_, id) => this.remove(id))
    }

    private add(n: Notifd.Notification) {
        // Filter out "100%" battery notifications from Bluetooth as they are often false positives on connect
        if (n.appName === "Bluetooth" && (n.summary.includes("100%") || n.body.includes("100%"))) {
            return
        }

        const list = [...this._popups]
        const idx = list.findIndex((x) => x.id === n.id)
        if (idx >= 0) {
            if (this.map.has(n.id)) {
                GLib.source_remove(this.map.get(n.id)!)
                this.map.delete(n.id)
            }
            list.splice(idx, 1)
        }

        const item: PopupItem = {
            n,
            id: n.id,
            state: new PopupState(),
        }

        list.unshift(item)
        this.popups = list

        const id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, TIMEOUT, () => {
            this.remove(n.id)
            return false
        })
        this.map.set(n.id, id)
    }

    private remove(id: number) {
        const item = this._popups.find((x) => x.id === id)
        if (!item) return

        // If already closing, return
        if (item.state.closing) return

        // Set closing state
        item.state.closing = true

        // Create a timeout to clean up after transition
        if (this.map.has(id)) {
            GLib.source_remove(this.map.get(id)!)
        }

        const cleanupId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, TRANSITION_DURATION, () => {
            const list = [...this._popups]
            const idx = list.findIndex((x) => x.id === id)
            if (idx >= 0) {
                list.splice(idx, 1)
                this.popups = list
            }
            this.map.delete(id)
            return false
        })
        this.map.set(id, cleanupId)
    }
}

const manager = new PopupManager()

export default function NotificationPopups(gdkmonitor: Gdk.Monitor) {
    const { TOP, RIGHT } = Astal.WindowAnchor

    const popups = createBinding(manager, "update").as(() => manager.popups)

    return (
        <Astal.Window
            name={`notifications-${gdkmonitor}`}
            namespace="notifications"
            class="NotificationPopups"
            gdkmonitor={gdkmonitor}
            layer={Astal.Layer.OVERLAY}
            anchor={TOP | RIGHT}
            marginRight={12}
            marginTop={12}
            widthRequest={400}
            defaultWidth={400}
            hexpand={true}
            visible={popups.as(l => l.length > 0)}
            application={App}
        >
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4} widthRequest={400} hexpand={false}>
                <For each={popups}>
                    {(item) => (
                        <NotificationItem
                            n={item.n}
                            isClosing={createBinding(item.state, "closing")}
                        />
                    )}
                </For>
            </box>
        </Astal.Window>
    )
}
