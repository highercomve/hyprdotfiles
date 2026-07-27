import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    color: "transparent"
    radius: Theme.moduleRadius
    border.color: Theme.borderColor
    border.width: 0
    implicitHeight: 30
    implicitWidth: row.implicitWidth + 12

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Loader {
            sourceComponent: {
                if (Ytm.hasTrack) return youtubeComponent
                if (activePlayer()) return mprisComponent
                return emptyComponent
            }
        }
    }

    Component {
        id: youtubeComponent
        RowLayout {
            spacing: 4

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: youtubeTitle.implicitWidth + 16
                radius: Theme.moduleRadius
                color: "transparent"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: ""
                        color: Theme.ytmColor
                        font.family: "Font Awesome 7 Free Solid"
                        font.pixelSize: 12
                    }

                    Text {
                        id: youtubeTitle
                        text: Ytm.currentTitle || "YouTube Music"
                        color: Theme.ytmColor
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Panels.toggleCenterPopup()
                }
            }

            ControlButton { icon: ""; onClicked: Ytm.pause() }
            ControlButton { icon: ""; onClicked: Ytm.next() }
        }
    }

    Component {
        id: mprisComponent
        RowLayout {
            spacing: 4

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: mprisTitle.implicitWidth + 16
                radius: Theme.moduleRadius
                color: "transparent"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: ""
                        color: Theme.text
                        font.family: "Font Awesome 7 Free Solid"
                        font.pixelSize: 12
                    }

                    Text {
                        id: mprisTitle
                        text: tickerText()
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Panels.toggleCenterPopup()
                }
            }

            ControlButton {
                icon: activePlayer()?.playbackState === MprisPlaybackState.Playing ? "" : ""
                onClicked: activePlayer()?.togglePlaying()
            }
            ControlButton { icon: ""; onClicked: activePlayer()?.next() }
        }
    }

    Component {
        id: emptyComponent
        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: emptyTitle.implicitWidth + 16
            radius: Theme.moduleRadius
            color: "transparent"

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: ""
                    color: Theme.text
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 12
                }

                Text {
                    id: emptyTitle
                    text: "No Media"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Panels.toggleCenterPopup()
            }
        }
    }

    Timer {
        interval: 1000
        running: !!activePlayer() && activePlayer().playbackState === MprisPlaybackState.Playing
        repeat: true
        onTriggered: tick++
    }

    property int tick: 0

    function activePlayer() {
        const players = Array.from(Mpris.players.values)
        const active = players.find(p => p.playbackState === MprisPlaybackState.Playing)
        return active || players[0] || null
    }

    function tickerText() {
        // Read tick unconditionally so the binding re-evaluates every second
        // while playing (position advances even for short, non-scrolling titles)
        const t = tick
        const p = activePlayer()
        if (!p) return "No Media"
        const title = p.trackTitle || "Unknown"
        const artist = p.trackArtist
        let content = artist ? title + " - " + artist : title
        const pos = p.position >= 0 ? p.position : 0
        const len = p.length > 0 ? p.length : 0
        const timeStr = "(" + formatTime(pos) + "/" + formatTime(len) + ")"

        if (content.length > 25) {
            const padded = content + "   "
            const start = tick % padded.length
            let slice = padded.slice(start, start + 25)
            if (slice.length < 25) slice += padded.slice(0, 25 - slice.length)
            content = slice
        }
        return content + " " + timeStr
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00"
        const min = Math.floor(seconds / 60)
        const sec = Math.floor(seconds % 60)
        return min + ":" + (sec < 10 ? "0" + sec : sec)
    }
}
