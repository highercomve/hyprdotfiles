pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    property bool dnd: false
    property var popups: []
    property var notifications: []

    NotificationServer {
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: (n) => {
            n.tracked = true

            if (n.appName === "Bluetooth" && (n.summary.includes("100%") || n.body.includes("100%"))) {
                return
            }

            // The server destroys the object when the sender closes the
            // notification (or it expires) — drop our reference then, or the
            // list renders dangling entries as blank cards.
            n.closed.connect(() => root.removeNotification(n))

            root.notifications.push(n)
            root.notifications = root.notifications.slice()

            if (!root.dnd) {
                root.addPopup(n)
            }
        }
    }

    function addPopup(n) {
        const list = root.popups.slice()
        const idx = list.findIndex(p => p.id === n.id)
        if (idx >= 0) list.splice(idx, 1)
        const popup = { n: n, id: n.id, closing: false, createdAt: Date.now() }
        list.unshift(popup)
        root.popups = list
        // Critical notifications (e.g. crash-watch) stay until acted on/dismissed.
        if (n.urgency !== NotificationUrgency.Critical) popupTimers.start(n.id)
    }

    function removePopup(id) {
        const list = root.popups.slice()
        const item = list.find(p => p.id === id)
        if (!item || item.closing) return
        item.closing = true
        root.popups = list
        popupTimers.cancel(id)
        closeTimer.start(id)
    }

    function removeNotification(n) {
        const idx = root.notifications.indexOf(n)
        if (idx >= 0) {
            const list = root.notifications.slice()
            list.splice(idx, 1)
            root.notifications = list
        }
        const popup = root.popups.find(p => p.n === n)
        if (popup) root.removePopup(popup.id)
    }

    function dismissNotification(n) {
        // dismiss() fires closed → removeNotification; the fallback covers
        // objects the server already destroyed, where dismiss() throws.
        try {
            n.dismiss()
        } catch (e) {
            root.removeNotification(n)
        }
    }

    function clearAll() {
        const list = root.notifications.slice()
        root.notifications = []
        root.popups = []
        popupTimers.clearAll()
        closeTimer.clearAll()
        list.forEach(n => {
            try { n.dismiss() } catch (e) {}
        })
    }

    function resolveIcon(n) {
        if (n.image) return n.image
        const candidates = []
        const entry = DesktopEntries.heuristicLookup(n.appName)
        if (entry?.icon) candidates.push(entry.icon)
        if (n.appIcon) candidates.push(n.appIcon)
        if (n.desktopEntry) candidates.push(n.desktopEntry)
        candidates.push("dialog-information-symbolic")
        for (const c of candidates) {
            const p = Quickshell.iconPath(c, true)
            if (p) return p
        }
        return ""
    }

    QtObject {
        id: popupTimers
        property var map: ({})

        function start(id) {
            if (map[id]) map[id].stop()
            const t = Qt.createQmlObject("import QtQuick; Timer { interval: 5000; repeat: false; property int popupId: 0; onTriggered: root.removePopup(popupId) }", root)
            t.popupId = id
            t.start()
            map[id] = t
        }

        function cancel(id) {
            if (map[id]) {
                map[id].stop()
                map[id].destroy()
                delete map[id]
            }
        }

        function clearAll() {
            for (const id in map) {
                if (map[id]) {
                    map[id].stop()
                    map[id].destroy()
                }
            }
            map = ({})
        }
    }

    QtObject {
        id: closeTimer
        property var map: ({})

        function start(id) {
            if (map[id]) map[id].destroy()
            const t = Qt.createQmlObject("import QtQuick; Timer { interval: 300; repeat: false; property int popupId: 0; onTriggered: root._finishClose(popupId) }", root)
            t.popupId = id
            t.triggered.connect(() => {
                if (map[id]) {
                    map[id].destroy()
                    delete map[id]
                }
            })
            t.start()
            map[id] = t
        }

        function clearAll() {
            for (const id in map) {
                if (map[id]) map[id].destroy()
            }
            map = ({})
        }
    }

    function _finishClose(id) {
        const list = root.popups.slice()
        const idx = list.findIndex(p => p.id === id)
        if (idx >= 0) {
            list.splice(idx, 1)
            root.popups = list
        }
    }
}
