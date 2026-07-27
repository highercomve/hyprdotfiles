import Quickshell
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

PanelPopup {
    id: centerPopup

    popupWidth: 800
    popupHeight: 500
    marginTop: 40
    marginRight: 0
    alignRight: false
    alignCenter: true

    visible: Panels.centerPopupOpen
    onCloseRequested: Panels.closeCenterPopup()

    panelContent: Rectangle {
        anchors.fill: parent
        color: Theme.base
        radius: 20
        border.color: Theme.surface1
        border.width: 1

        RowLayout {
            anchors {
                fill: parent
                margins: 24
            }
            spacing: 20

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    CalendarView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // Hidden for now per user request; set visible: true to restore
                    YouTubeSearch {
                        visible: false
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: "#1affffff"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                MediaPlayer {
                    anchors.fill: parent
                }
            }
        }
    }
}
