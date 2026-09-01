pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Lightweight plugin registry: plugins.json (quickshell root) is the single
// source of truth. A plugin is a folder plugins/<id>/ with conventional entry
// files (Service.qml, BarWidget.qml, Panel.qml) — which of them exist is
// declared by its "kinds". Enable/disable + bar placement live in the same
// file. Restart the shell (launch.sh) after editing; QML is not hot-reloaded.
Singleton {
    id: root

    property var config: ({})
    // Live service instances by plugin id. Replaced-on-write so bindings that
    // read it (duck-typed injection in PluginHost/PluginSlot) stay reactive.
    property var services: ({})

    readonly property var pluginList: {
        const plugins = config.plugins || {}
        const out = []
        for (const id in plugins) {
            const p = plugins[id]
            if (p.enabled === false) continue
            out.push({
                id: id,
                kinds: p.kinds || [],
                settings: p.settings || {},
                dir: Quickshell.shellDir + "/plugins/" + id
            })
        }
        return out
    }

    readonly property var servicePlugins: pluginList.filter(p => p.kinds.indexOf("service") !== -1)
    readonly property var panelPlugins: pluginList.filter(p => p.kinds.indexOf("panel") !== -1)

    function _slot(name) {
        return ((config.bar || {})[name] || [])
            .map(id => pluginList.find(p => p.id === id))
            .filter(p => p && p.kinds.indexOf("barWidget") !== -1)
    }
    readonly property var barWidgets: ({
        left: _slot("left"),
        center: _slot("center"),
        right: _slot("right")
    })

    function registerService(id, obj) {
        const m = Object.assign({}, services); m[id] = obj; services = m
    }
    function unregisterService(id) {
        const m = Object.assign({}, services); delete m[id]; services = m
    }

    FileView {
        path: Quickshell.shellDir + "/plugins.json"
        blockLoading: true
        onLoaded: root._parse(text())
        onLoadFailed: root.config = {}
    }
    function _parse(t) {
        try { root.config = JSON.parse(t) }
        catch (e) { console.warn("PluginRegistry: plugins.json parse failed:", e); root.config = {} }
    }
}
