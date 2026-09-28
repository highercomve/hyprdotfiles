import QtQuick

import "../Theme"

Rectangle {
    id: root

    property string icon: ""
    property string fontFamily: Theme.fontFamily
    property bool active: false
    property color activeColor: Theme.blue
    property string tooltip: ""

    signal clicked()
    signal rightClicked()
    signal middleClicked()

    width: 24
    height: 24
    radius: Theme.moduleRadius
    color: "transparent"

    BarTooltip {
        target: root
        text: root.tooltip
        shown: mouse.containsMouse
    }

    Text {
        anchors.centerIn: parent
        text: parent.icon
        color: parent.active ? parent.activeColor : Theme.text
        font.family: parent.fontFamily
        font.pixelSize: 12
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.rightClicked()
            else if (mouse.button === Qt.MiddleButton) root.middleClicked()
            else root.clicked()
        }
    }
}
