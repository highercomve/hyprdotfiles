import Quickshell
import Quickshell.Networking as QN
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    id: root

    color: "transparent"
    anchors.fill: parent

    property string selectedSsid: ""
    property bool showPassword: false

    // Keep the scanner running while this page is open. The Networking backend
    // takes a few seconds to initialize, so retry instead of scanning once.
    Component.onCompleted: {
        Network.scan()
        Network.refresh()
    }
    Component.onDestruction: Network.stopScan()

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            Network.scan()
            Network.refresh()
        }
    }

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
                text: "Wi-Fi"
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
            visible: Network.wiredConnected !== undefined

            RowLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 8

                Text {
                    text: ""
                    color: Theme.text
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 16
                }

                Text {
                    text: "Ethernet"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 24
                    radius: 12
                    color: Network.wiredConnected ? Theme.blue : Theme.surface0

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Network.toggleWired(!Network.wiredConnected)
                    }

                    Rectangle {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: Network.wiredConnected ? undefined : parent.left
                            right: Network.wiredConnected ? parent.right : undefined
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
                    text: "Wi-Fi"
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
                        text: Network.scanning ? "" : ""
                        color: Theme.subtext0
                        font.family: "Font Awesome 7 Free Solid"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Network.scan()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 24
                    radius: 12
                    color: Network.wifiEnabled ? Theme.blue : Theme.surface0

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Network.setWifiEnabled(!Network.wifiEnabled)
                    }

                    Rectangle {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: Network.wifiEnabled ? undefined : parent.left
                            right: Network.wifiEnabled ? parent.right : undefined
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
                model: Network.accessPoints

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 36
                    radius: Theme.moduleRadius
                    color: modelData.connected ? Theme.surface1 : "transparent"

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: 8
                        }
                        spacing: 8

                        Text {
                            text: wifiIcon(modelData.signalStrength)
                            color: Theme.subtext0
                            font.family: "Font Awesome 7 Free Solid"
                            font.pixelSize: 16
                        }

                        Text {
                            text: modelData.ssid
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: ""
                            color: Theme.subtext0
                            font.family: "Font Awesome 7 Free Solid"
                            font.pixelSize: 12
                            visible: modelData.security !== QN.WifiSecurityType.Open
                        }

                        Text {
                            text: ""
                            color: Theme.blue
                            font.family: "Font Awesome 7 Free Solid"
                            font.pixelSize: 14
                            visible: modelData.connected
                        }

                        Text {
                            text: ""
                            color: Theme.red
                            font.family: "Font Awesome 7 Free Solid"
                            font.pixelSize: 12
                            visible: modelData.known && !modelData.connected

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Network.forgetAp(modelData.ssid)
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.security !== QN.WifiSecurityType.Open && !modelData.known) {
                                root.selectedSsid = modelData.ssid
                                root.showPassword = true
                            } else {
                                Network.connectAp(modelData.ssid)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: Theme.surface0
            radius: 12
            visible: root.showPassword

            RowLayout {
                anchors {
                    fill: parent
                    margins: 8
                }
                spacing: 8

                Text {
                    text: "Password"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                }

                TextInput {
                    id: passwordInput
                    Layout.fillWidth: true
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    echoMode: TextInput.Password
                    text: ""
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 24
                    radius: 12
                    color: Theme.blue

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Network.connectAp(root.selectedSsid, passwordInput.text)
                            root.showPassword = false
                            passwordInput.text = ""
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: Theme.base
                        font.family: "Font Awesome 7 Free Solid"
                        font.pixelSize: 14
                    }
                }
            }
        }
    }

    function wifiIcon(strength) {
        if (strength >= 80) return ""
        if (strength >= 60) return ""
        if (strength >= 40) return ""
        if (strength >= 20) return ""
        return ""
    }
}
