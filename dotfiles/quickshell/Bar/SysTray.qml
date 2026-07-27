import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../Theme"

Rectangle {
    color: "transparent"
    implicitHeight: 30
    implicitWidth: row.implicitWidth + 4

    TrayMenu {
        id: trayMenu
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: SystemTray.items

            Rectangle {
                id: trayItem
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: Theme.moduleRadius
                color: "transparent"

                ToolTip.text: modelData.tooltipTitle || ""
                ToolTip.visible: trayMouse.containsMouse && !!modelData.tooltipTitle
                ToolTip.delay: 500

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: modelData.icon || ""
                    cache: true
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                            showMenu()
                        } else {
                            modelData.activate()
                        }
                    }

                    function showMenu() {
                        if (!modelData.hasMenu) return
                        const win = trayItem.QsWindow.window
                        if (!win) return
                        const p = win.contentItem.mapFromItem(trayItem, 0, 0)
                        trayMenu.openAt(modelData.menu, p.x)
                    }
                }
            }
        }
    }
}
