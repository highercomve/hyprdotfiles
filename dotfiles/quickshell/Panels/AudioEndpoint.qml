import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

import "../Theme"

Rectangle {
    id: root

    property string label: ""
    property var device: null
    property bool expanded: false
    property bool isInput: false

    color: "transparent"
    implicitHeight: contentCol.implicitHeight

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.moduleRadius
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: device?.audio?.muted ? "" : ""
                    color: Theme.text
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: device.audio.muted = !device.audio.muted
                }
            }

            Rectangle {
                id: volumeSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                color: "transparent"

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    height: 6
                    radius: 3
                    color: Theme.surface0
                }

                Rectangle {
                    id: volumeFill
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    width: parent.width * (device?.audio?.volume || 0)
                    height: 6
                    radius: 3
                    color: Theme.blue
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width, volumeFill.width - width / 2))
                    width: 16
                    height: 16
                    radius: 8
                    color: Theme.text
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        device.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
                    }
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            device.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredHeight: 32
                Layout.preferredWidth: nameRow.implicitWidth + 8
                color: "transparent"

                RowLayout {
                    id: nameRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: device?.description || label
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.maximumWidth: 120
                    }

                    Text {
                        text: expanded ? "" : ""
                        color: Theme.subtext0
                        font.family: "Font Awesome 7 Free Solid"
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: expanded = !expanded
                }
            }
        }

        // Expanded: pick which device becomes the default output/input
        DeviceList {
            visible: opacity > 0
            opacity: root.expanded ? 1 : 0
            Layout.fillWidth: true
            Layout.leftMargin: 32
            isInput: root.isInput

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }
    }
}
