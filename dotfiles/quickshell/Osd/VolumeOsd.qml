import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

import "../Theme"

PanelWindow {
    id: osd

    required property var modelData
    screen: modelData

    anchors.bottom: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    width: osdRow.implicitWidth + 48
    height: 64
    visible: false
    color: "transparent"

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.base
        radius: Theme.osdRadius
        opacity: 0.9
        border.color: Theme.surface1
        border.width: 1

        RowLayout {
            id: osdRow
            anchors.centerIn: parent
            spacing: 16

            Text {
                text: Pipewire.defaultAudioSink?.audio?.muted ? "" : ""
                color: Theme.text
                font.family: "Font Awesome 7 Free Solid"
                font.pixelSize: 24
            }

            Rectangle {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 8
                radius: 99
                color: Theme.surface0

                Rectangle {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    width: parent.width * (Pipewire.defaultAudioSink?.audio?.volume || 0)
                    height: parent.height
                    radius: 99
                    color: Theme.blue
                }
            }

            Text {
                text: Math.round((Pipewire.defaultAudioSink?.audio?.volume || 0) * 100) + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.bold: true
                Layout.preferredWidth: 40
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: osd.visible = false
    }

    function show() {
        osd.visible = true
        hideTimer.restart()
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null
        enabled: target !== null
        function onVolumeChanged() { osd.show() }
        function onMutedChanged() { osd.show() }
    }

    // Also show on sink change (e.g. default device switch)
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() { osd.show() }
    }
}
