import QtQuick

import "../Theme"

Rectangle {
    id: root

    property string icon: ""
    property string fontFamily: Theme.fontFamily
    property bool active: false
    property color activeColor: Theme.blue

    signal clicked()

    width: 24
    height: 24
    radius: Theme.moduleRadius
    color: "transparent"

    Text {
        anchors.centerIn: parent
        text: parent.icon
        color: parent.active ? parent.activeColor : Theme.text
        font.family: parent.fontFamily
        font.pixelSize: 12
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
