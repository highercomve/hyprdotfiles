pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Normalized output of ai_usage.sh: [{id, name, plan, ok, stale, error,
    // limits: [{label, percent, resetsAt}]}]
    property var providers: []
    property string updatedAt: ""
    property bool refreshing: false
    property double _lastFetch: 0

    readonly property real worstPercent: {
        let worst = 0
        for (const p of providers)
            for (const l of (p.limits || []))
                if (typeof l.percent === "number" && l.percent > worst)
                    worst = l.percent
        return worst
    }

    // The Anthropic endpoint dislikes probes more often than every ~3 min.
    Timer {
        interval: 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: proc
        command: ["bash", Quickshell.shellDir + "/ai_usage.sh"]
        stdout: StdioCollector { onStreamFinished: root._apply(text) }
        onExited: root.refreshing = false
    }

    function refresh() {
        if (proc.running) return
        refreshing = true
        proc.running = true
    }

    function refreshIfStale() {
        if (Date.now() - _lastFetch > 120000) refresh()
    }

    function _apply(output) {
        try {
            const json = JSON.parse(output.trim())
            root.providers = json.providers || []
            root.updatedAt = json.updatedAt || ""
            root._lastFetch = Date.now()
        } catch (e) {
            console.warn("AiUsage: collector output parse failed:", e)
        }
    }
}
