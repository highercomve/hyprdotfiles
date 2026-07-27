import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

ColumnLayout {
    spacing: 8
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Notifications"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.bold: true
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: Theme.moduleRadius
            color: clearMouse.containsMouse ? Theme.surface1 : "transparent"
            visible: NotificationStore.notifications.length > 0

            Text {
                anchors.centerIn: parent
                text: ""
                color: Theme.subtext0
                font.family: "Font Awesome 7 Free Solid"
                font.pixelSize: 13
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationStore.clearAll()
            }
        }
    }

    Repeater {
        model: NotificationStore.notifications

        NotificationItem {
            notification: modelData
        }
    }

    Text {
        text: "No notifications"
        color: Theme.overlay0
        font.family: Theme.fontFamily
        font.pixelSize: 14
        visible: NotificationStore.notifications.length === 0
        Layout.alignment: Qt.AlignHCenter
    }
}
