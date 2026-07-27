pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool reveal: false
    property string idle: ""
    property string sunset: ""
    property string record: ""
    property string monitorSuspend: ""
    property string powerProfile: ""

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.poll()
    }

    Timer {
        id: delayedPoll
        interval: 500
        repeat: false
        onTriggered: root.poll()
    }

    Process {
        id: idleProc
        command: ["bash", "-c", "~/.config/hypr/scripts/hypridle.sh status"]
        stdout: StdioCollector { onStreamFinished: root._applyStatus(text, "idle") }
    }

    Process {
        id: sunsetProc
        command: ["bash", "-c", "~/.config/hypr/scripts/hyprsunset.sh status"]
        stdout: StdioCollector { onStreamFinished: root._applyStatus(text, "sunset") }
    }

    Process {
        id: recordProc
        command: ["bash", "-c", "~/.config/hypr/scripts/record.sh status"]
        stdout: StdioCollector { onStreamFinished: root._applyStatus(text, "record") }
    }

    Process {
        id: monitorProc
        command: ["bash", "-c", "~/.config/hypr/scripts/monitor-suspend.sh status"]
        stdout: StdioCollector { onStreamFinished: root._applyStatus(text, "monitorSuspend") }
    }

    Process {
        id: toggleProc
        command: []
        onExited: delayedPoll.start()
    }

    Process {
        id: powerGetProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: root.handlePowerGet(text) }
    }

    Process {
        id: powerSetProc
        command: []
        onExited: (exitCode) => {
            if (exitCode !== 0) console.warn("powerprofilesctl set failed with code", exitCode)
            delayedPoll.start()
        }
    }

    Component.onCompleted: root.poll()

    function poll() {
        idleProc.running = true
        sunsetProc.running = true
        recordProc.running = true
        monitorProc.running = true
        powerGetProc.running = true
    }

    function _applyStatus(output, prop) {
        try {
            const json = JSON.parse(output.trim())
            const value = json.class || json.alt || json.text || ""
            root[prop] = value
        } catch (e) {
            console.warn("Tools status parse failed for", prop, ":", e)
        }
    }

    function toggle(script) {
        toggleProc.command = ["bash", "-c", script + " toggle"]
        toggleProc.running = true
    }

    function cyclePowerProfile() {
        powerGetProc.running = true
    }

    function handlePowerGet(output) {
        const profiles = ["power-saver", "balanced", "performance"]
        const current = output.trim()
        const idx = profiles.indexOf(current)
        if (idx < 0) {
            console.warn("Unknown power profile:", current)
            return
        }
        const next = profiles[(idx + 1) % profiles.length]
        powerSetProc.command = ["powerprofilesctl", "set", next]
        powerSetProc.running = true
    }
}
