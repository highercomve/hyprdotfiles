import QtQuick
import "../Services"

// A bar mount point. Place inside a Row/RowLayout with position "left",
// "center" or "right"; renders the enabled plugin bar widgets listed under
// that key in plugins.json, in list order.
Repeater {
    id: slot

    property string position: "right"

    model: PluginRegistry.barWidgets[slot.position]

    delegate: Loader {
        source: modelData.dir + "/BarWidget.qml"
        onLoaded: {
            if ("pluginId" in item) item.pluginId = modelData.id
            if ("settings" in item) item.settings = modelData.settings
            if ("service" in item) item.service =
                Qt.binding(() => PluginRegistry.services[modelData.id] ?? null)
        }
    }
}
