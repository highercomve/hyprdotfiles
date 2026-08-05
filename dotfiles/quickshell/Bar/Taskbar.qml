import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../Theme"

Rectangle {
    color: Theme.surface0
    radius: Theme.moduleRadius
    border.color: Theme.borderColor
    border.width: 1
    implicitHeight: 30
    implicitWidth: row.implicitWidth + 12
    visible: row.implicitWidth > 0

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: {
                const list = Array.from(Hyprland.toplevels.values)
                list.sort((a, b) => a.workspace.id - b.workspace.id)
                return list
            }

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: Theme.moduleRadius
                color: "transparent"

                ToolTip.text: modelData.title
                ToolTip.visible: mouseArea.containsMouse
                ToolTip.delay: 500

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: iconForClass(modelData.lastIpcObject?.class || modelData.wayland?.appId || "")
                    cache: true
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Hyprland's Lua dispatch requires the 0x prefix; Quickshell reports
                        // the address bare, so normalize before building the argument.
                        const addr = String(modelData.address).replace(/^0x/, "")
                        Hyprland.dispatch("hl.dsp.focus({ window = \"address:0x" + addr + "\" })")
                    }
                }
            }
        }
    }

    function substituteClass(className) {
        const map = {
            "dev.zed.Zed": "zed"
        }
        return map[className] || className
    }

    function iconForClass(className) {
        const name = substituteClass(className)
        const entry = DesktopEntries.heuristicLookup(name)
        const iconName = entry?.iconName || name
        return Quickshell.iconPath(iconName, "application-x-executable")
    }
}
