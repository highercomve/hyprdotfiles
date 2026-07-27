import QtQuick

import "../Theme"

Rectangle {
    id: root

    property string icon: ""

    signal clicked()

    width: 24
    height: 24
    radius: Theme.moduleRadius
    color: "transparent"

    Text {
        anchors.centerIn: parent
        text: parent.icon
        color: Theme.text
        font.family: "Font Awesome 7 Free Solid"
        font.pixelSize: 12
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
