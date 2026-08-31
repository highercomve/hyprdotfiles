import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "../Theme"

PanelWindow {
    id: barWindow

    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Auto
    height: 38
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Theme.barBackground

        RowLayout {
            id: leftBox
            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
                leftMargin: 8
            }
            spacing: 4

            Workspaces {}
            Taskbar {}
            ClientTitle {}
        }

        // Clock + media share one island with a divider, like AGS group-center
        Rectangle {
            id: centerGroup
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            implicitHeight: 30
            implicitWidth: centerRow.implicitWidth + 24
            radius: Theme.moduleRadius
            color: Theme.surface0
            border.color: Theme.borderColor
            border.width: 1

            RowLayout {
                id: centerRow
                anchors.centerIn: parent
                spacing: 8

                Item {
                    implicitWidth: Math.max(180, clockWidget.implicitWidth)
                    implicitHeight: 30
                    ClockWidget { id: clockWidget; anchors.centerIn: parent }
                }

                Rectangle {
                    implicitWidth: 1
                    Layout.fillHeight: true
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    color: "#33ffffff"
                }

                Item {
                    implicitWidth: Math.max(180, mediaBar.implicitWidth)
                    implicitHeight: 30
                    MediaBar { id: mediaBar; anchors.centerIn: parent }
                }
            }
        }

        RowLayout {
            id: rightBox
            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
                rightMargin: 8
            }
            spacing: 4

            AiUsageWidget {}
            SystemMonitor {}
            ToolsRow {}

            // Battery, tray, quick settings and power share one island (AGS group-system)
            Rectangle {
                implicitHeight: 30
                implicitWidth: sysRow.implicitWidth + 20
                radius: Theme.moduleRadius
                color: Theme.surface0
                border.color: Theme.borderColor
                border.width: 1

                RowLayout {
                    id: sysRow
                    anchors.centerIn: parent
                    spacing: 4

                    BatteryLevel {}
                    SysTray {}
                    QuickSettings {}
                    PowerMenu { Layout.leftMargin: 8 }
                }
            }
        }
    }
}
