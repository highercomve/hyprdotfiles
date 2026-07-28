import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    id: root
    color: "transparent"
    implicitHeight: content.implicitHeight

    property bool adding: false

    // Called from suggestion delegates; runs on root because changing the
    // filter destroys the delegate mid-handler, skipping its remaining lines
    function finishAdd(entry) {
        WorldClocks.addCity(entry.tz, entry.label)
        root.adding = false
        searchInput.text = ""
    }

    function suggestions() {
        const query = searchInput.text.trim().toLowerCase()
        if (query.length < 2) return []
        // Word-prefix name matches beat country/region/substring matches;
        // population breaks ties
        const tier = e => (e.nameKey.startsWith(query) || e.nameKey.includes(" " + query)) ? 0 : 1
        return WorldClocks.searchEntries
            .filter(e => e.key.includes(query))
            .sort((a, b) => (tier(a) - tier(b)) || (b.pop - a.pop))
            .slice(0, 4)
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: ""
                color: Theme.sapphire
                font.family: "Font Awesome 7 Free Solid"
                font.pixelSize: 14
            }

            Text {
                text: "World Clock"
                color: Theme.sapphire
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: Theme.moduleRadius
                color: root.adding ? Theme.surface1 : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: root.adding ? "" : ""
                    color: root.adding ? Theme.red : Theme.sapphire
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.adding = !root.adding
                        searchInput.text = ""
                        if (root.adding) searchInput.forceActiveFocus()
                    }
                }
            }
        }

        Rectangle {
            visible: root.adding
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 8
            color: Theme.surface0

            TextInput {
                id: searchInput
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 13
                clip: true
                onAccepted: {
                    const matches = root.suggestions()
                    if (matches.length > 0) root.finishAdd(matches[0])
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search city or timezone..."
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    visible: searchInput.text.length === 0
                }
            }
        }

        Repeater {
            model: root.adding ? root.suggestions() : []

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                radius: 6
                color: suggestionHover.hovered ? Theme.surface1 : "transparent"

                Text {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: 10
                        rightMargin: 10
                    }
                    text: modelData.display
                    elide: Text.ElideRight
                    color: Theme.subtext1
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }

                HoverHandler { id: suggestionHover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.finishAdd(modelData)
                }
            }
        }

        Text {
            visible: !root.adding && WorldClocks.cities.length === 0
            text: "No cities yet — add one with +"
            color: Theme.overlay0
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Repeater {
            model: WorldClocks.cities

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 6
                color: cityHover.hovered ? Theme.surface0 : "transparent"

                HoverHandler { id: cityHover }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                    }
                    spacing: 8

                    Text {
                        text: modelData.label
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        property var info: WorldClocks.times[modelData.tz]
                        text: info ? info.day + " · " + info.offset : ""
                        color: Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    Text {
                        property var info: WorldClocks.times[modelData.tz]
                        text: info ? info.time : "--:--"
                        color: Theme.blue
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        radius: 4
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: removeHover.hovered ? Theme.red : Theme.surface2
                            font.family: "Font Awesome 7 Free Solid"
                            font.pixelSize: 11
                        }

                        HoverHandler { id: removeHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WorldClocks.removeCity(modelData.tz)
                        }
                    }
                }
            }
        }
    }
}
