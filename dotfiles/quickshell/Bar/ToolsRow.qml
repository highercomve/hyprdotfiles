import Quickshell
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    color: Theme.surface0
    radius: Theme.moduleRadius
    border.color: Theme.borderColor
    border.width: 1
    implicitHeight: 30
    implicitWidth: row.implicitWidth + 12

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Rectangle {
            id: toolsContainer
            Layout.preferredWidth: Tools.reveal ? toolsLayout.implicitWidth : 0
            Layout.preferredHeight: 24
            clip: true
            color: "transparent"

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }

            RowLayout {
                id: toolsLayout
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                ToolButton {
                    icon: ""
                    fontFamily: "Font Awesome 7 Free Solid"
                    onClicked: Tools.toggle("~/.config/hypr/scripts/cliphist.sh")
                }

                ToolButton {
                    icon: ""
                    fontFamily: "Font Awesome 7 Free Solid"
                    active: Tools.idle === "active"
                    activeColor: Theme.mauve
                    onClicked: Tools.toggle("~/.config/hypr/scripts/hypridle.sh")
                }

                ToolButton {
                    icon: ""
                    fontFamily: "Font Awesome 7 Free Solid"
                    active: Tools.sunset === "active"
                    activeColor: Theme.sapphire
                    onClicked: Tools.toggle("~/.config/hypr/scripts/hyprsunset.sh")
                }

                ToolButton {
                    icon: ""
                    fontFamily: "Font Awesome 7 Free Solid"
                    active: Tools.record === "recording"
                    activeColor: Theme.red
                    onClicked: Tools.toggle("~/.config/hypr/scripts/record.sh")
                }

                ToolButton {
                    icon: ""
                    fontFamily: "Font Awesome 7 Free Solid"
                    active: Tools.monitorSuspend === "active"
                    activeColor: Theme.green
                    onClicked: Tools.toggle("~/.config/hypr/scripts/monitor-suspend.sh")
                }

                ToolButton {
                    icon: ""
                    fontFamily: "Font Awesome 7 Free Solid"
                    activeColor: Theme.yellow
                    onClicked: Tools.cyclePowerProfile()
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: Theme.moduleRadius
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: ""
                color: Theme.toolsToggle
                font.family: "Font Awesome 7 Free Solid"
                font.pixelSize: 12
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Tools.reveal = !Tools.reveal
            }
        }
    }
}
