import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

import "../Theme"

Rectangle {
    color: "transparent"
    anchors.fill: parent

    property var player: activePlayer()
    property real posFrac: 0

    Timer {
        interval: 1000
        running: player?.isPlaying ?? false
        repeat: true
        triggeredOnStart: true
        onTriggered: updatePlayer()
    }

    function updatePlayer() {
        player = activePlayer()
        posFrac = player && player.length > 0 ? player.position / player.length : 0
    }

    onPlayerChanged: posFrac = player && player.length > 0 ? player.position / player.length : 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 200
            Layout.preferredHeight: 200
            radius: 12
            color: Theme.surface0

            Image {
                anchors.fill: parent
                source: player?.trackArtUrl || ""
                fillMode: Image.PreserveAspectCrop
                visible: !!player?.trackArtUrl
                cache: true
            }

            Text {
                anchors.centerIn: parent
                text: ""
                color: Theme.subtext0
                font.family: "Font Awesome 7 Free Solid"
                font.pixelSize: 64
                visible: !player?.trackArtUrl
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Text {
                text: player?.trackTitle || "No Media Playing"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                Layout.maximumWidth: 300
            }

            Text {
                text: player?.trackArtist || ""
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: 15
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                Layout.maximumWidth: 300
            }

            Text {
                text: player?.trackAlbum || ""
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                Layout.maximumWidth: 300
                visible: text.length > 0
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Theme.surface0

            Rectangle {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: parent.width * posFrac
                height: parent.height
                radius: 3
                color: Theme.blue
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (player && player.length > 0) {
                        player.seek(player.length * Math.max(0, Math.min(1, mouse.x / width)) - player.position)
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.text
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 18
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: player?.previous()
                }
            }

            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                radius: 28
                color: Theme.blue

                Text {
                    anchors.centerIn: parent
                    text: player?.playbackState === MprisPlaybackState.Playing ? "" : ""
                    color: Theme.base
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 22
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: player?.togglePlaying()
                }
            }

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.text
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 18
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: player?.next()
                }
            }
        }
    }

    function activePlayer() {
        const players = Array.from(Mpris.players.values)
        const active = players.find(p => p.playbackState === MprisPlaybackState.Playing)
        return active || players[0] || null
    }
}
