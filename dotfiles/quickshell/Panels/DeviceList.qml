import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

import "../Theme"

ColumnLayout {
    property bool isInput: false
    spacing: 4

    Repeater {
        model: Pipewire.nodes

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: Theme.moduleRadius
            color: "transparent"
            visible: matchesType(modelData)

            Text {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 8
                }
                text: modelData.description || modelData.name
                color: isDefault(modelData) ? Theme.blue : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 14
                elide: Text.ElideRight
                width: parent.width - 32
            }

            Text {
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: 8
                }
                text: ""
                color: Theme.blue
                font.family: "Font Awesome 7 Free Solid"
                font.pixelSize: 14
                visible: isDefault(modelData)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: setDefault(modelData)
            }
        }
    }

    Item { Layout.fillHeight: true }

    function matchesType(node) {
        // PwNodeType values are bitflags sharing the Audio bit, so a plain
        // `type & AudioSink` also matches audio sources (e.g. headset mics).
        if (node.isStream || !(node.type & PwNodeType.Audio)) return false
        return isInput ? !node.isSink : node.isSink
    }

    function isDefault(node) {
        if (isInput) return node === Pipewire.defaultAudioSource
        return node === Pipewire.defaultAudioSink
    }

    function setDefault(node) {
        if (isInput) Pipewire.preferredDefaultAudioSource = node
        else Pipewire.preferredDefaultAudioSink = node
    }
}
