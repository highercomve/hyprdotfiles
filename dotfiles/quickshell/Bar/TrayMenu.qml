import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "../Theme"

// Custom styled popover for tray menus (platform menus don't map on this
// quickshell build). Fullscreen overlay; backdrop click closes.
PanelWindow {
    id: menuWindow

    property var handle: null
    property real menuX: 0
    property int barHeight: 38

    function openAt(h, x) {
        menuX = x
        handle = h
    }

    function close() {
        handle = null
    }

    visible: handle !== null
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    QsMenuOpener {
        id: opener
        menu: menuWindow.handle
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: menuWindow.close()
    }

    Rectangle {
        x: Math.max(8, Math.min(menuWindow.menuX, menuWindow.width - width - 8))
        y: menuWindow.barHeight + 4
        width: 240
        height: Math.min(menuCol.implicitHeight + 16, menuWindow.height - menuWindow.barHeight - 24)
        radius: 12
        color: Theme.base
        border.color: Theme.surface1
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        ColumnLayout {
            id: menuCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 2

            Repeater {
                model: opener.children

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: modelData.isSeparator ? 9 : 32
                    radius: 8
                    color: entryMouse.containsMouse && !modelData.isSeparator && modelData.enabled ? Theme.surface1 : "transparent"

                    Rectangle {
                        visible: modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Theme.surface1
                    }

                    RowLayout {
                        visible: !modelData.isSeparator
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 8

                        Image {
                            visible: (modelData.icon || "") !== ""
                            source: modelData.icon || ""
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            fillMode: Image.PreserveAspectFit
                        }

                        Text {
                            text: modelData.text || ""
                            color: modelData.enabled ? Theme.text : Theme.overlay0
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !modelData.isSeparator && modelData.enabled
                        onClicked: {
                            modelData.triggered()
                            menuWindow.close()
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: menuWindow.visible
        Keys.onEscapePressed: menuWindow.close()
    }
}
