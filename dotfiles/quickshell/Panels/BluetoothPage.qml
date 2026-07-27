import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    color: "transparent"
    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: "transparent"

            Rectangle {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: 32
                height: 32
                radius: Theme.moduleRadius
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.text
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Panels.switchControlPanelPage("main")
                }
            }

            Text {
                anchors.centerIn: parent
                text: "Bluetooth"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 17
                font.bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: Theme.mantle
            radius: 12

            RowLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                Text {
                    text: "Bluetooth"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: Theme.moduleRadius
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: Bluetooth.defaultAdapter?.discovering ? "" : ""
                        color: Theme.subtext0
                        font.family: "Font Awesome 7 Free Solid"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toggleDiscovery()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 24
                    radius: 12
                    color: Bluetooth.defaultAdapter?.enabled ? Theme.blue : Theme.surface0

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Bluetooth.defaultAdapter) {
                                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                            }
                        }
                    }

                    Rectangle {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: Bluetooth.defaultAdapter?.enabled ? undefined : parent.left
                            right: Bluetooth.defaultAdapter?.enabled ? parent.right : undefined
                            leftMargin: 2
                            rightMargin: 2
                        }
                        width: 20
                        height: 20
                        radius: 10
                        color: Theme.text
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.mantle
            radius: 12

            ListView {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                clip: true
                model: sortedDevices()

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 40
                    radius: Theme.moduleRadius
                    color: modelData.connected ? Theme.surface1 : "transparent"

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: 8
                        }
                        spacing: 8

                        Text {
                            text: bluetoothIcon(modelData.icon)
                            color: Theme.subtext0
                            font.family: "Font Awesome 7 Free Solid"
                            font.pixelSize: 16
                        }

                        Text {
                            text: modelData.name || modelData.deviceName || "Unknown"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: Math.round(modelData.battery * 100) + "%"
                            color: Theme.subtext0
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            visible: modelData.batteryAvailable
                        }

                        Text {
                            text: ""
                            color: Theme.blue
                            font.family: "Font Awesome 7 Free Solid"
                            font.pixelSize: 14
                            visible: modelData.connected
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.connected) {
                                modelData.disconnect()
                            } else {
                                if (!modelData.paired) {
                                    modelData.pair()
                                } else {
                                    modelData.connect()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function sortedDevices() {
        const list = Array.from(Bluetooth.devices.values)
        list.sort((a, b) => Number(b.connected) - Number(a.connected))
        return list
    }

    function toggleDiscovery() {
        if (!Bluetooth.defaultAdapter) return
        if (Bluetooth.defaultAdapter.discovering) {
            Bluetooth.defaultAdapter.discovering = false
        } else {
            Bluetooth.defaultAdapter.discovering = true
            discoveryTimer.start()
        }
    }

    function bluetoothIcon(iconName) {
        if (!iconName) return ""
        if (iconName.includes("audio-headset") || iconName.includes("headphones")) return ""
        if (iconName.includes("input-keyboard")) return ""
        if (iconName.includes("input-mouse")) return ""
        if (iconName.includes("phone")) return ""
        return ""
    }

    Timer {
        id: discoveryTimer
        interval: 15000
        repeat: false
        onTriggered: {
            if (Bluetooth.defaultAdapter) {
                Bluetooth.defaultAdapter.discovering = false
            }
        }
    }
}
