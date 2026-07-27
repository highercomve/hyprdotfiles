import Quickshell
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    id: root
    property var notification: null
    property bool closing: false

    color: Theme.base
    radius: 12
    border.color: Theme.surface1
    border.width: 1
    Layout.fillWidth: true
    Layout.preferredHeight: column.implicitHeight + 24

    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }
    opacity: closing ? 0 : 1

    ColumnLayout {
        id: column
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Image {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                source: notification ? NotificationStore.resolveIcon(notification) : ""
                visible: source != ""
                cache: true
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: notification?.summary || ""
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: notification?.body || ""
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    maximumLineCount: expanded ? 0 : 2
                    elide: Text.ElideRight
                    textFormat: Text.StyledText
                    property bool expanded: false

                    MouseArea {
                        anchors.fill: parent
                        onClicked: parent.expanded = !parent.expanded
                    }
                }

                Text {
                    text: notification ? new Date(notification.createdAt || Date.now()).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) : ""
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: Theme.moduleRadius
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.subtext0
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.notification) {
                            NotificationStore.dismissNotification(root.notification)
                            root.closing = true
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: notification?.actions?.length > 0

            Repeater {
                model: notification?.actions || []

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: Theme.moduleRadius
                    color: Theme.surface0
                    visible: (modelData.text || "") !== ""

                    Text {
                        anchors.centerIn: parent
                        text: modelData.text || ""
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
