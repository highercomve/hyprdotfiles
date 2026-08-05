import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import "../Theme"

Rectangle {
    color: Theme.surface0
    radius: Theme.moduleRadius
    border.color: Theme.borderColor
    border.width: 1
    implicitHeight: 30
    implicitWidth: row.implicitWidth + 8

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: {
                const list = Array.from(Hyprland.workspaces.values)
                list.sort((a, b) => a.id - b.id)
                return list
            }

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: Theme.moduleRadius
                color: modelData === Hyprland.focusedWorkspace ? Theme.wsActiveBg : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: modelData.id
                    color: modelData === Hyprland.focusedWorkspace ? Theme.wsActiveFg : Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: modelData === Hyprland.focusedWorkspace
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
                }
            }
        }
    }
}
