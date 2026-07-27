import QtQuick
import QtQuick.Layouts

import "../Theme"

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false

    signal clicked()
    signal detailRequested()

    color: active ? Theme.blue : Theme.surface0
    radius: Theme.pillRadius

    Behavior on color {
        ColorAnimation {
            duration: 180
        }
    }
    implicitHeight: 44
    implicitWidth: 160

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            radius: Theme.pillRadius

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clicked()
            }

            RowLayout {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 12
                }
                spacing: 8

                Text {
                    text: root.icon
                    color: active ? Theme.base : Theme.text
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 16
                }

                Text {
                    text: root.label
                    color: active ? Theme.base : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Medium
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: "#1affffff"
        }

        Rectangle {
            Layout.preferredWidth: 44
            Layout.fillHeight: true
            color: "transparent"
            radius: Theme.pillRadius

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.detailRequested()
            }

            Text {
                anchors.centerIn: parent
                text: ""
                color: active ? Theme.base : Theme.text
                font.family: "Font Awesome 7 Free Solid"
                font.pixelSize: 14
            }
        }
    }
}
