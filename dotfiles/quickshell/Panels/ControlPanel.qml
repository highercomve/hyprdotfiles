import Quickshell
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

PanelPopup {
    id: controlPanel

    popupWidth: 400
    popupHeight: 800
    marginTop: 40
    marginRight: 5
    alignRight: true

    visible: Panels.controlPanelOpen
    onCloseRequested: Panels.closeControlPanel()

    panelContent: Rectangle {
        anchors.fill: parent
        color: Theme.base
        radius: Theme.panelRadius
        border.color: Theme.surface1
        border.width: 1

        Loader {
            id: pageLoader
            anchors {
                fill: parent
                margins: 16
            }
            source: {
                switch (Panels.controlPanelPage) {
                case "network": return "NetworkPage.qml"
                case "bluetooth": return "BluetoothPage.qml"
                case "audio": return "AudioPage.qml"
                default: return "MainPage.qml"
                }
            }
            onLoaded: pageFade.restart()

            NumberAnimation {
                id: pageFade
                target: pageLoader.item
                property: "opacity"
                from: 0
                to: 1
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }
}
