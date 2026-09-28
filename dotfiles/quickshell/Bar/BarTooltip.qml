import Quickshell
import QtQuick

import "../Theme"

// Tooltip as its own surface below the bar. QtQuick.Controls' ToolTip gets
// clamped inside the short bar window, lands on top of the button and eats
// its clicks.
PopupWindow {
    id: root

    property Item target
    property string text: ""
    property bool shown: false

    anchor.item: target
    anchor.rect.x: target ? (target.width - implicitWidth) / 2 : 0
    anchor.rect.y: target ? target.height + 8 : 0
    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 10
    color: "transparent"
    mask: Region {}
    visible: false

    Timer {
        id: delay
        interval: 500
        onTriggered: root.visible = root.text !== ""
    }

    onShownChanged: {
        if (shown) delay.restart()
        else { delay.stop(); visible = false }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface0
        radius: Theme.moduleRadius
        border.color: Theme.borderColor
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }
}
