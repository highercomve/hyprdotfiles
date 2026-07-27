import Quickshell
import QtQuick

import "../Services"
import "../Theme"

Rectangle {
    color: "transparent"
    implicitHeight: 30
    implicitWidth: label.implicitWidth + 20

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: true
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "hh:mm AP - dd MMM")
        color: Theme.clockColor
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.toggleCenterPopup()
    }
}
