import Quickshell
import QtQuick

import "../Theme"

Rectangle {
    color: "transparent"
    implicitWidth: 24
    implicitHeight: 30

    Text {
        anchors.centerIn: parent
        text: ""
        color: Theme.powerColor
        font.family: "Font Awesome 7 Free Solid"
        font.pixelSize: 14
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/wlogout.sh"])
    }
}
