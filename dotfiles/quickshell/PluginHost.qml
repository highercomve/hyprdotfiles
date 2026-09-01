import Quickshell
import QtQuick
import "Services"

// Mounts non-bar plugin surfaces: headless services and panel windows.
// Bar widgets are mounted by Bar/PluginSlot.qml. Duck-typed injection: a
// plugin root declares only the properties it wants (pluginId, settings,
// service) and the host fills them.
Scope {
    id: host

    function inject(item, meta) {
        if ("pluginId" in item) item.pluginId = meta.id
        if ("settings" in item) item.settings = meta.settings
        if ("service" in item) item.service =
            Qt.binding(() => PluginRegistry.services[meta.id] ?? null)
    }

    // Services: headless Item roots, registered so widgets/panels can bind.
    Instantiator {
        model: PluginRegistry.servicePlugins
        delegate: Loader {
            source: modelData.dir + "/Service.qml"
            onLoaded: {
                host.inject(item, modelData)
                PluginRegistry.registerService(modelData.id, item)
            }
            Component.onDestruction: PluginRegistry.unregisterService(modelData.id)
        }
    }

    // Panels: window roots (PanelPopup), so LazyLoader rather than Loader.
    // Always loaded (visibility is gated by Panels.isOpen), matching how the
    // hardcoded popups behave.
    Instantiator {
        model: PluginRegistry.panelPlugins
        delegate: LazyLoader {
            active: true
            source: modelData.dir + "/Panel.qml"
            onItemChanged: if (item) host.inject(item, modelData)
        }
    }
}
