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
                    tooltip: "Clipboard history (right: wipe, middle: delete entry)"
                    onClicked: Tools.toggle("~/.config/hypr/scripts/cliphist.sh")
                    onRightClicked: Tools.run("~/.config/hypr/scripts/cliphist.sh w")
                    onMiddleClicked: Tools.run("~/.config/hypr/scripts/cliphist.sh d")
                }

                ToolButton {
                    icon: ""
                    fontFamily: "Font Awesome 7 Free Solid"
                    tooltip: "Auto screen lock (hypridle): " + (Tools.idle === "active" ? "on" : "off")
                    active: Tools.idle === "active"
                    activeColor: Theme.mauve
                    onClicked: Tools.toggle("~/.config/hypr/scripts/hypridle.sh")
                }

                ToolButton {
                    icon: ""
                    fontFamily: "Font Awesome 7 Free Solid"
                    tooltip: "Night light: " + (Tools.sunset === "active" ? "on" : "off")
                    active: Tools.sunset === "active"
                    activeColor: Theme.sapphire
                    onClicked: Tools.toggle("~/.config/hypr/scripts/hyprsunset.sh")
                }

                ToolButton {
                    icon: "\uf042"
                    fontFamily: "Font Awesome 7 Free Solid"
                    tooltip: "Screen shader (hyprshade): " + (Tools.shade === "active" ? "on" : "off") + " (right: choose filter)"
                    active: Tools.shade === "active"
                    activeColor: Theme.peach
                    onClicked: Tools.toggle("~/.config/hypr/scripts/hyprshade.sh")
                    onRightClicked: Tools.run("~/.config/hypr/scripts/hyprshade.sh rofi")
                }

                ToolButton {
                    icon: ""
                    fontFamily: "Font Awesome 7 Free Solid"
                    tooltip: Tools.record === "recording" ? "Stop screen recording" : "Start screen recording"
                    active: Tools.record === "recording"
                    activeColor: Theme.red
                    onClicked: Tools.toggle("~/.config/hypr/scripts/record.sh")
                }

                ToolButton {
                    icon: ""
                    fontFamily: "Font Awesome 7 Free Solid"
                    tooltip: "Power profile: " + (Tools.powerProfile || "unknown") + " (click to cycle)"
                    activeColor: Theme.yellow
                    onClicked: Tools.cyclePowerProfile()
                }
            }
        }

        Rectangle {
            id: revealButton
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

            BarTooltip {
                target: revealButton
                text: Tools.reveal ? "Hide tools" : "Show tools"
                shown: revealMouse.containsMouse
            }

            MouseArea {
                id: revealMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Tools.reveal = !Tools.reveal
            }
        }
    }
}
