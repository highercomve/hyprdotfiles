pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int cpu: 0
    property string memory: "0.0"
    property int temp: 0

    property var _prevCpu: ({ total: 0, idle: 0 })
    property string _hwmonPath: ""
    property bool _hwmonReady: false

    property var _hwmonNames: ["coretemp", "k10temp", "zenpower"]

    Process {
        id: hwmonProc
        command: ["bash", "-c", "for d in /sys/class/hwmon/hwmon*; do echo \"$d $(cat \"$d/name\" 2>/dev/null)\"; done"]
        stdout: StdioCollector { onStreamFinished: root.handleHwmon(text) }
    }

    FileView {
        id: cpuFile
        path: "/proc/stat"
        watchChanges: false
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        watchChanges: false
    }

    FileView {
        id: tempFile
        path: root._hwmonPath
        watchChanges: true
        onTextChanged: root.updateTemp()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.update()
    }

    Component.onCompleted: hwmonProc.running = true

    function handleHwmon(output) {
        const lines = output.trim().split("\n")
        let chosenPath = ""

        for (const name of root._hwmonNames) {
            for (const line of lines) {
                const parts = line.split(" ")
                if (parts.length >= 2 && parts[parts.length - 1] === name) {
                    const dir = parts.slice(0, parts.length - 1).join(" ")
                    const t1 = dir + "/temp1_input"
                    const t3 = dir + "/temp3_input"
                    // prefer temp1_input on coretemp, temp3_input on k10temp/zenpower
                    if (name === "coretemp") {
                        chosenPath = t1
                    } else {
                        chosenPath = t3
                    }
                    break
                }
            }
            if (chosenPath) break
        }

        // Fallback: first hwmon with any temp*_input
        if (!chosenPath) {
            for (const line of lines) {
                const parts = line.split(" ")
                const dir = parts.slice(0, parts.length - 1).join(" ")
                // probe temp1_input
                // we cannot synchronously test file existence from qml, so guess temp1_input
                if (dir) {
                    chosenPath = dir + "/temp1_input"
                    break
                }
            }
        }

        root._hwmonPath = chosenPath
        root._hwmonReady = true
        root.updateTemp()
    }

    function update() {
        updateCpu()
        updateMemory()
        updateTemp()
    }

    function updateCpu() {
        const text = cpuFile.text()
        const line = text.split("\n").find(l => l.startsWith("cpu "))
        if (!line) return
        const parts = line.trim().split(/\s+/).slice(1).map(Number)
        if (parts.length < 4) return
        const idle = parts[3] + (parts[4] || 0)
        const total = parts.reduce((a, b) => a + b, 0)
        const deltaTotal = total - _prevCpu.total
        const deltaIdle = idle - _prevCpu.idle
        if (deltaTotal > 0) {
            cpu = Math.round((1 - deltaIdle / deltaTotal) * 100)
        }
        _prevCpu = { total, idle }
    }

    function updateMemory() {
        const text = memFile.text()
        const totalMatch = text.match(/MemTotal:\s+(\d+)/)
        const availableMatch = text.match(/MemAvailable:\s+(\d+)/)
        if (totalMatch && availableMatch) {
            const total = parseInt(totalMatch[1])
            const available = parseInt(availableMatch[1])
            const used = total - available
            memory = (used / 1048576).toFixed(1)
        }
    }

    function updateTemp() {
        if (!_hwmonReady || !_hwmonPath) return
        const raw = tempFile.text().trim()
        if (!raw) return
        temp = Math.round(parseInt(raw) / 1000)
    }
}
