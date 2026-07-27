import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    color: "transparent"
    anchors.fill: parent

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
                source: Ytm.currentCover || ""
                fillMode: Image.PreserveAspectCrop
                visible: !!Ytm.currentCover
            }

            Text {
                anchors.centerIn: parent
                text: ""
                color: Theme.subtext0
                font.family: "Font Awesome 7 Free Solid"
                font.pixelSize: 64
                visible: !Ytm.currentCover
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Text {
                text: Ytm.currentTitle || "YouTube Music"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                Layout.maximumWidth: 300
            }

            Text {
                text: Ytm.currentArtist || "Search for a song"
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: 15
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                Layout.maximumWidth: 300
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
                width: parent.width * (Ytm.duration > 0 ? Ytm.position / Ytm.duration : 0)
                height: parent.height
                radius: 3
                color: Theme.blue
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => Ytm.seek(Ytm.duration * Math.max(0, Math.min(1, mouse.x / width)))
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
                    onClicked: Ytm.previous()
                }
            }

            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                radius: 28
                color: Theme.blue

                Text {
                    anchors.centerIn: parent
                    text: Ytm.isPlaying ? "" : ""
                    color: Theme.base
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 22
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Ytm.isPlaying ? Ytm.pause() : Ytm.resume()
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
                    onClicked: Ytm.next()
                }
            }
        }
    }
}
