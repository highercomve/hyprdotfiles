import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    color: Theme.surface0
    radius: Theme.moduleRadius
    border.color: Theme.borderColor
    border.width: 1
    implicitHeight: 30
    implicitWidth: row.implicitWidth + 12

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: "<span style=\"font-family: 'Font Awesome 7 Free Solid'; color:" + Theme.cpuColor + "\"></span> " + SystemStats.cpu + "%"
            color: Theme.cpuColor
            font.family: Theme.fontFamily
            font.pixelSize: 12
            textFormat: Text.RichText
            ToolTip.text: "CPU Usage"
            ToolTip.visible: cpuMouse.containsMouse
            ToolTip.delay: 500

            MouseArea {
                id: cpuMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        Text {
            text: "<span style=\"font-family: 'Font Awesome 7 Free Solid'; color:" + Theme.memoryColor + "\"></span> " + SystemStats.memory + "G"
            color: Theme.memoryColor
            font.family: Theme.fontFamily
            font.pixelSize: 12
            textFormat: Text.RichText
            ToolTip.text: "Memory Usage"
            ToolTip.visible: memMouse.containsMouse
            ToolTip.delay: 500

            MouseArea {
                id: memMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        Text {
            text: "<span style=\"font-family: 'Font Awesome 7 Free Solid'; color:" + Theme.tempColor + "\"></span> " + SystemStats.temp + "°C"
            color: Theme.tempColor
            font.family: Theme.fontFamily
            font.pixelSize: 12
            textFormat: Text.RichText
            ToolTip.text: "CPU Temperature"
            ToolTip.visible: tempMouse.containsMouse
            ToolTip.delay: 500

            MouseArea {
                id: tempMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/user_settings/system-monitor.sh"])
    }
}
