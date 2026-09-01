import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../Services"
import "../../Theme"

// Bar module: AI icon + the worst utilization across all subscriptions.
// Click opens the plugin's panel.
Rectangle {
    id: widget

    property string pluginId: ""
    property var settings: ({})
    property var service: null

    color: Theme.surface0
    radius: Theme.moduleRadius
    border.color: Theme.borderColor
    border.width: 1
    implicitHeight: 30
    implicitWidth: row.implicitWidth + 20

    readonly property real worst: service ? service.worstPercent : 0
    readonly property color accentBase:
        (settings.accent && Theme[settings.accent] !== undefined)
            ? Theme[settings.accent] : Theme.teal
    readonly property color accent: worst >= 90 ? Theme.red
        : worst >= 70 ? Theme.yellow
        : accentBase

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "" // robot
            color: widget.accent
            font.family: "Font Awesome 7 Free Solid"
            font.pixelSize: 12
        }

        Text {
            text: Math.round(widget.worst) + "%"
            color: widget.accent
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: aiMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggle(widget.pluginId)
    }

    ToolTip.text: "AI subscription usage"
    ToolTip.visible: aiMouse.containsMouse
    ToolTip.delay: 500
}
