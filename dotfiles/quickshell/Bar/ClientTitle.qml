import Quickshell.Hyprland
import QtQuick

import "../Theme"

Rectangle {
    color: Theme.surface0
    radius: Theme.moduleRadius
    border.color: Theme.borderColor
    border.width: 1
    implicitHeight: 30
    implicitWidth: Math.min(label.implicitWidth + 20, 280)
    visible: Hyprland.activeToplevel?.title?.length > 0

    Text {
        id: label
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            leftMargin: 10
            rightMargin: 10
        }
        text: Hyprland.activeToplevel?.title || ""
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        elide: Text.ElideRight
    }
}
