import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Panels"

PanelWindow {
    id: popupWindow

    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.margins.top: 12
    WlrLayershell.margins.right: 12
    width: 400
    height: popupColumn.implicitHeight + 24
    visible: NotificationStore.popups.length > 0
    color: "transparent"

    ColumnLayout {
        id: popupColumn
        anchors {
            top: parent.top
            right: parent.right
            margins: 12
        }
        spacing: 8

        Repeater {
            model: NotificationStore.popups

            NotificationItem {
                notification: modelData.n
                closing: modelData.closing
            }
        }
    }
}
