pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real screen: 0
    property bool available: false

    property int _max: 0
    property string _brightnessPath: ""

    FileView {
        id: brightnessFile
        path: root._brightnessPath
        watchChanges: true
        onTextChanged: root.readBrightness()
    }

    Component.onCompleted: root.initialize()

    Process {
        id: listProc
        command: ["brightnessctl", "--class=backlight", "list"]
        stdout: StdioCollector { onStreamFinished: root.handleList(text) }
    }

    Process {
        id: maxProc
        command: ["brightnessctl", "max"]
        stdout: StdioCollector { onStreamFinished: root.handleMax(text) }
    }

    Process {
        id: getProc
        command: ["brightnessctl", "get"]
        stdout: StdioCollector { onStreamFinished: root.handleGet(text) }
    }

    Process {
        id: pathProc
        command: []
        stdout: StdioCollector { onStreamFinished: root.handlePath(text) }
    }

    Process {
        id: setProc
        command: []
        onExited: (exitCode) => {
            if (exitCode !== 0) console.warn("brightnessctl set failed with code", exitCode)
        }
    }

    function initialize() {
        listProc.running = true
    }

    function handleList(output) {
        if (!output || output.includes("No devices found")) {
            root.available = false
            return
        }
        maxProc.running = true
    }

    function handleMax(output) {
        const max = Number(output.trim())
        if (!Number.isFinite(max) || max <= 0) {
            root.available = false
            return
        }
        root._max = max
        getProc.running = true
    }

    function handleGet(output) {
        const current = Number(output.trim())
        if (Number.isFinite(current)) {
            root.screen = Math.max(0, Math.min(1, current / root._max))
        }
        findBrightnessPath()
        root.available = true
    }

    function findBrightnessPath() {
        pathProc.command = ["bash", "-c", "find /sys/class/backlight -maxdepth 2 -name brightness -print -quit 2>/dev/null"]
        pathProc.running = true
    }

    function handlePath(output) {
        const path = output.trim()
        if (path) root._brightnessPath = path
    }

    function readBrightness() {
        if (!available || !_max || !_brightnessPath) return
        const current = Number(brightnessFile.text.trim())
        if (!Number.isFinite(current)) return
        const value = Math.max(0, Math.min(1, current / _max))
        if (Math.abs(value - screen) > 0.01) screen = value
    }

    function setValue(percent) {
        if (!available) return
        const value = Math.max(0, Math.min(1, percent))
        setProc.command = ["brightnessctl", "set", Math.round(value * 100) + "%", "-q"]
        setProc.running = true
        screen = value
    }
}
