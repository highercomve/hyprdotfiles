import Quickshell
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
                text: "Audio Devices"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 17
                font.bold: true
            }
        }

        Text {
            text: "Output"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.mantle
            radius: 12

            DeviceList {
                anchors.fill: parent
                anchors.margins: 10
                isInput: false
            }
        }

        Text {
            text: "Input"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.mantle
            radius: 12

            DeviceList {
                anchors.fill: parent
                anchors.margins: 10
                isInput: true
            }
        }
    }
}
