import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

import "../Services"
import "../Theme"

Rectangle {
    color: "transparent"
    implicitWidth: 48
    implicitHeight: 30

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Row {
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: dndIcon
            text: NotificationStore.dnd ? "" : ""
            color: Theme.text
            font.family: "Font Awesome 7 Free Solid"
            font.pixelSize: 12
        }

        Text {
            id: volIcon
            text: Pipewire.defaultAudioSink?.audio?.muted ? "" : ""
            color: Theme.mauve
            font.family: "Font Awesome 7 Free Solid"
            font.pixelSize: 12
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggleControlPanel()
    }
}
