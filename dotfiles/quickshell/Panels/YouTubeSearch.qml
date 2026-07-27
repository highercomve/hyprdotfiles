import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: ""
                color: Theme.subtext0
                font.family: "Font Awesome 7 Free Solid"
                font.pixelSize: 16
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 8
                color: Theme.surface0

                TextInput {
                    id: searchInput
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    clip: true
                    text: Ytm.searchQuery
                    onTextEdited: Ytm.searchQuery = text
                    onAccepted: Ytm.search(text, Ytm.searchFilter)

                    Text {
                        anchors.fill: parent
                        text: "Search YouTube Music..."
                        color: Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        visible: searchInput.text.length === 0
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Repeater {
                model: [
                    { label: "Songs", value: "songs" },
                    { label: "Artists", value: "artists" },
                    { label: "Albums", value: "albums" },
                    { label: "Playlists", value: "playlists" }
                ]

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: pillText.implicitWidth + 16
                    radius: 12
                    color: Ytm.searchFilter === modelData.value ? Theme.blue : Theme.surface0

                    Text {
                        id: pillText
                        anchors.centerIn: parent
                        text: modelData.label
                        color: Ytm.searchFilter === modelData.value ? Theme.base : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Ytm.search(Ytm.searchQuery, modelData.value)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.mantle
            radius: 12

            Text {
                anchors.centerIn: parent
                text: "Searching..."
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: 15
                visible: Ytm.isSearching
            }

            ListView {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                clip: true
                model: Ytm.searchResults
                visible: !Ytm.isSearching

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 56
                    radius: Theme.moduleRadius
                    color: "transparent"

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: 8
                        }
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: modelData.type === "artist" ? 22 : 6
                            color: Theme.surface0

                            Image {
                                anchors.fill: parent
                                source: modelData.thumbnail || ""
                                fillMode: Image.PreserveAspectCrop
                                visible: !!modelData.thumbnail
                                cache: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.name || "Unknown"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: (modelData.artist || "") + " • " + (modelData.type || "")
                                color: Theme.subtext0
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            radius: Theme.moduleRadius
                            color: "transparent"
                            visible: modelData.type === "song"

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: Theme.subtext0
                                font.family: "Font Awesome 7 Free Solid"
                                font.pixelSize: 14
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Ytm.startRadio(modelData.id)
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.type === "song" || modelData.type === "video") {
                                Ytm.play(modelData.id, modelData.name, modelData.artist, modelData.thumbnail, true)
                            } else {
                                Ytm.searchQuery = modelData.name
                                Ytm.searchFilter = "songs"
                                Ytm.search(modelData.name, "songs")
                            }
                        }
                    }
                }
            }
        }
    }
}
