import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    color: "transparent"
    Layout.fillWidth: true
    Layout.preferredHeight: 32

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            text: "Do not disturb"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 24
            radius: 12
            color: NotificationStore.dnd ? Theme.blue : Theme.surface0

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationStore.dnd = !NotificationStore.dnd
            }

            Rectangle {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: NotificationStore.dnd ? undefined : parent.left
                    right: NotificationStore.dnd ? parent.right : undefined
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
