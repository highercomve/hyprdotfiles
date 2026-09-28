import Quickshell
import QtQuick
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
            id: cpuText
            text: "<span style=\"font-family: 'Font Awesome 7 Free Solid'; color:" + Theme.cpuColor + "\"></span> " + SystemStats.cpu + "%"
            color: Theme.cpuColor
            font.family: Theme.fontFamily
            font.pixelSize: 12
            textFormat: Text.RichText
            BarTooltip {
                target: cpuText
                text: "CPU Usage"
                shown: cpuMouse.containsMouse
            }

            MouseArea {
                id: cpuMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        Text {
            id: memText
            text: "<span style=\"font-family: 'Font Awesome 7 Free Solid'; color:" + Theme.memoryColor + "\"></span> " + SystemStats.memory + "G"
            color: Theme.memoryColor
            font.family: Theme.fontFamily
            font.pixelSize: 12
            textFormat: Text.RichText
            BarTooltip {
                target: memText
                text: "Memory Usage"
                shown: memMouse.containsMouse
            }

            MouseArea {
                id: memMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        Text {
            id: tempText
            text: "<span style=\"font-family: 'Font Awesome 7 Free Solid'; color:" + Theme.tempColor + "\"></span> " + SystemStats.temp + "°C"
            color: Theme.tempColor
            font.family: Theme.fontFamily
            font.pixelSize: 12
            textFormat: Text.RichText
            BarTooltip {
                target: tempText
                text: "CPU Temperature"
                shown: tempMouse.containsMouse
            }

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
