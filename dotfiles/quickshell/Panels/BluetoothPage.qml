import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    id: root
    color: "transparent"
    anchors.fill: parent

    // Pairing needs a BlueZ agent to answer confirmation requests; this page
    // has none of its own and relies on blueman-applet.service.
    property bool agentRunning: true

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
            Layout.preferredHeight: 40
            visible: !root.agentRunning
            color: Qt.alpha(Theme.red, 0.15)
            radius: 12

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 8
                }
                spacing: 8

                Text {
                    text: "\uf071"
                    color: Theme.red
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 14
                }

                Text {
                    text: "No pairing agent running"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.preferredWidth: startLabel.implicitWidth + 16
                    Layout.preferredHeight: 26
                    radius: Theme.moduleRadius
                    color: startHover.hovered ? Theme.surface1 : Theme.surface0

                    Text {
                        id: startLabel
                        anchors.centerIn: parent
                        text: "Start"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }

                    HoverHandler { id: startHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.startAgent()
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
                    id: row

                    required property var modelData
                    readonly property var device: modelData

                    // Set when this page started a pair/connect, so a device
                    // that settles unpaired/disconnected is reported as failed.
                    property bool pairRequested: false
                    property bool connectRequested: false
                    property string errorText: ""

                    readonly property string statusText: {
                        if (errorText) return errorText
                        if (device.pairing) return "Pairing\u2026"
                        if (device.state === BluetoothDeviceState.Connecting) return "Connecting\u2026"
                        if (device.state === BluetoothDeviceState.Disconnecting) return "Disconnecting\u2026"
                        return ""
                    }

                    width: ListView.view.width
                    height: statusText ? 52 : 40
                    radius: Theme.moduleRadius
                    color: device.connected ? Theme.surface1 : "transparent"

                    // Declared before the row so the forget button stays clickable.
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.activate()
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: 8
                        }
                        spacing: 8

                        Text {
                            text: bluetoothIcon(row.device.icon)
                            color: Theme.subtext0
                            font.family: "Font Awesome 7 Free Solid"
                            font.pixelSize: 16
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: row.device.name || row.device.deviceName || "Unknown"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: row.statusText
                                visible: text !== ""
                                color: row.errorText ? Theme.red : Theme.subtext0
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: Math.round(row.device.battery * 100) + "%"
                            color: Theme.subtext0
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            visible: row.device.batteryAvailable
                        }

                        Text {
                            text: "\uf00c"
                            color: Theme.blue
                            font.family: "Font Awesome 7 Free Solid"
                            font.pixelSize: 14
                            visible: row.device.connected
                        }

                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 4
                            color: "transparent"
                            visible: row.device.paired || row.device.trusted

                            Text {
                                anchors.centerIn: parent
                                text: "\uf2ed"
                                color: forgetHover.hovered ? Theme.red : Theme.surface2
                                font.family: "Font Awesome 7 Free Solid"
                                font.pixelSize: 12
                            }

                            HoverHandler { id: forgetHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                // Forget removes the device and its cached
                                // GATT/HID data; re-pairing starts clean.
                                onClicked: {
                                    row.pairRequested = false
                                    row.connectRequested = false
                                    row.errorText = ""
                                    row.device.forget()
                                }
                            }
                        }
                    }

                    function activate() {
                        errorText = ""
                        if (device.pairing) {
                            pairRequested = false
                            device.cancelPair()
                        } else if (device.connected) {
                            connectRequested = false
                            device.disconnect()
                        } else if (!device.paired) {
                            root.checkAgent()
                            pairRequested = true
                            device.pair()
                        } else {
                            connectRequested = true
                            device.connect()
                        }
                    }

                    // The Paired property can land just after the pair call
                    // returns, so give BlueZ a moment before calling it failed.
                    Timer {
                        id: pairSettle
                        interval: 1500
                        onTriggered: {
                            if (!row.pairRequested || row.device.pairing) return
                            row.pairRequested = false
                            if (!row.device.paired) {
                                root.checkAgent()
                                row.errorText = root.agentRunning
                                    ? "Pairing failed \u2014 put the device in pairing mode"
                                    : "Pairing failed \u2014 no pairing agent"
                            }
                        }
                    }

                    Timer {
                        id: connectSettle
                        interval: 1500
                        onTriggered: {
                            if (!row.connectRequested) return
                            if (row.device.state !== BluetoothDeviceState.Disconnected) return
                            row.connectRequested = false
                            row.errorText = "Connection failed"
                        }
                    }

                    Connections {
                        target: row.device

                        function onPairingChanged() {
                            if (!row.device.pairing && row.pairRequested) pairSettle.restart()
                        }

                        function onPairedChanged() {
                            if (!row.device.paired || !row.pairRequested) return
                            // Trust so it reconnects on its own, then connect.
                            row.pairRequested = false
                            row.device.trusted = true
                            row.connectRequested = true
                            row.device.connect()
                        }

                        function onStateChanged() {
                            if (row.device.state === BluetoothDeviceState.Connected) {
                                row.connectRequested = false
                                row.errorText = ""
                            } else if (row.device.state === BluetoothDeviceState.Disconnected && row.connectRequested) {
                                connectSettle.restart()
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

    function checkAgent() {
        agentCheck.running = true
    }

    function startAgent() {
        Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/blueman-applet.sh start"])
        agentRecheck.restart()
    }

    Process {
        id: agentCheck
        command: ["systemctl", "--user", "is-active", "blueman-applet.service"]
        stdout: StdioCollector {
            onStreamFinished: root.agentRunning = text.trim() === "active"
        }
    }

    Timer {
        id: agentRecheck
        interval: 1500
        onTriggered: root.checkAgent()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkAgent()
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
