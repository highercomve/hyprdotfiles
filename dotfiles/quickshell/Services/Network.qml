pragma Singleton
import Quickshell
import Quickshell.Networking
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool wifiEnabled: Networking.wifiEnabled
    property bool scanning: false
    property bool wiredConnected: false
    property var accessPoints: []

    Component.onCompleted: root.refresh()

    // Toggle the radio through nmcli (like AGS does); Networking.wifiEnabled
    // then updates via NetworkManager's own signal and the UI follows.
    function setWifiEnabled(on) {
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"])
    }

    // Wired toggle uses nmcli exactly like AGS.
    function toggleWired(active) {
        const action = active ? "connect" : "disconnect"
        Quickshell.execDetached(["sh", "-c",
            "nmcli -t -f TYPE,DEVICE device | grep '^ethernet:' | head -1 | cut -d: -f2 | xargs -r nmcli device " + action])
    }

    function connectAp(ssid, psk) {
        for (const ap of root.accessPoints) {
            if (ap.ssid === ssid) {
                if (psk) ap.connectWithPsk(psk)
                else ap.connect()
                return
            }
        }
    }

    function forgetAp(ssid) {
        for (const ap of root.accessPoints) {
            if (ap.ssid === ssid) {
                ap.forget()
                return
            }
        }
    }

    // The Networking backend only tracks wifi devices, so ethernet state
    // comes from nmcli instead.
    Process {
        id: wiredCheck
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE device 2>/dev/null | grep '^ethernet:' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: root.wiredConnected = text.includes(":connected")
        }
    }

    function refresh() {
        wiredCheck.running = true

        const wifiDev = findWifiDevice()
        root.scanning = wifiDev?.scannerEnabled || false

        const newAps = collectAps()
        if (!apsEqual(newAps, root.accessPoints)) {
            root.accessPoints = newAps
        }
    }

    function findWifiDevice() {
        for (const dev of Networking.devices.values) {
            if (dev.type === DeviceType.Wifi) return dev
        }
        return null
    }

    function scan() {
        const dev = findWifiDevice()
        if (dev) dev.scannerEnabled = true
    }

    function stopScan() {
        const dev = findWifiDevice()
        if (dev) dev.scannerEnabled = false
    }

    function collectAps() {
        const aps = []
        const seen = new Set()
        for (const dev of Networking.devices.values) {
            if (dev.type !== DeviceType.Wifi) continue
            for (const net of dev.networks.values) {
                if (!net.name) continue
                if (seen.has(net.name)) continue
                seen.add(net.name)
                aps.push({
                    ssid: net.name,
                    name: net.name,
                    signalStrength: net.signalStrength,
                    connected: net.connected,
                    known: net.known,
                    security: net.security,
                    connect: () => net.connect(),
                    connectWithPsk: (psk) => net.connectWithPsk(psk),
                    forget: () => net.forget()
                })
            }
        }
        aps.sort((a, b) => b.signalStrength - a.signalStrength)
        return aps
    }

    function apsEqual(a, b) {
        if (a.length !== b.length) return false
        for (let i = 0; i < a.length; i++) {
            if (a[i].ssid !== b[i].ssid ||
                a[i].signalStrength !== b[i].signalStrength ||
                a[i].connected !== b[i].connected) return false
        }
        return true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
