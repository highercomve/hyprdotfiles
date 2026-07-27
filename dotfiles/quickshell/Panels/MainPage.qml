import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    color: "transparent"
    anchors.fill: parent

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 8

                TogglePill {
                    Layout.fillWidth: true
                    icon: ""
                    label: "Wi-Fi"
                    active: Network.wifiEnabled
                    onClicked: Network.setWifiEnabled(!Network.wifiEnabled)
                    onDetailRequested: Panels.switchControlPanelPage("network")
                }

                TogglePill {
                    Layout.fillWidth: true
                    icon: ""
                    label: "Bluetooth"
                    active: Bluetooth.defaultAdapter?.enabled || false
                    onClicked: {
                        if (Bluetooth.defaultAdapter) {
                            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                        }
                    }
                    onDetailRequested: Panels.switchControlPanelPage("bluetooth")
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Theme.mantle
            radius: 12
            visible: Brightness.available

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                Text {
                    text: "Brightness"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: ""
                        color: Theme.text
                        font.family: "Font Awesome 7 Free Solid"
                        font.pixelSize: 16
                    }

                    Rectangle {
                        id: brightnessSlider
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
                            id: brightnessFill
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                            }
                            width: parent.width * Brightness.screen
                            height: 6
                            radius: 3
                            color: Theme.blue
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, brightnessFill.width - width / 2))
                            width: 16
                            height: 16
                            radius: 8
                            color: Theme.text
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                Brightness.setValue(Math.max(0, Math.min(1, mouse.x / width)))
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    Brightness.setValue(Math.max(0, Math.min(1, mouse.x / width)))
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: Theme.mantle
            radius: 12

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Panels.switchControlPanelPage("audio")
            }

            RowLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                Text {
                    text: ""
                    color: Theme.text
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 16
                }

                Text {
                    text: "Manage Audio Devices"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: ""
                    color: Theme.subtext0
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 14
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: audioColumn.implicitHeight + 24
            color: Theme.mantle
            radius: 12

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                id: audioColumn
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                Text {
                    text: "Audio"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                }

                AudioEndpoint {
                    Layout.fillWidth: true
                    label: "Speaker"
                    device: Pipewire.defaultAudioSink
                    isInput: false
                    expanded: false
                }

                AudioEndpoint {
                    Layout.fillWidth: true
                    label: "Microphone"
                    device: Pipewire.defaultAudioSource
                    isInput: true
                    expanded: false
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.mantle
            radius: 12

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                DndSwitch {}
                NotificationList {}
                Item { Layout.fillHeight: true }
            }
        }
    }
}
