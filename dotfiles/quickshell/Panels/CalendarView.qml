import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../Theme"

Rectangle {
    id: root
    color: "transparent"

    property int displayMonth: new Date().getMonth()
    property int displayYear: new Date().getFullYear()

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.moduleRadius
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.text
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.previousMonth()
                }
            }

            Text {
                text: calendarMonth.title
                color: Theme.sapphire
                font.family: Theme.fontFamily
                font.pixelSize: 17
                font.bold: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.moduleRadius
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Theme.text
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextMonth()
                }
            }
        }

        DayOfWeekRow {
            Layout.fillWidth: true
            locale: Qt.locale()

            delegate: Text {
                text: shortName
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
            }
        }

        MonthGrid {
            id: calendarMonth
            Layout.fillWidth: true
            Layout.fillHeight: true
            month: root.displayMonth
            year: root.displayYear
            locale: Qt.locale()

            delegate: Rectangle {
                width: 40
                height: 32
                radius: 6
                color: model.today ? Theme.blue : (model.month === calendarMonth.month ? "transparent" : Theme.surface0)

                Text {
                    anchors.centerIn: parent
                    text: model.day
                    color: model.today ? Theme.base : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: model.today
                }
            }
        }
    }

    function previousMonth() {
        let m = root.displayMonth - 1
        let y = root.displayYear
        if (m < 0) { m = 11; y -= 1 }
        root.displayMonth = m
        root.displayYear = y
    }

    function nextMonth() {
        let m = root.displayMonth + 1
        let y = root.displayYear
        if (m > 11) { m = 0; y += 1 }
        root.displayMonth = m
        root.displayYear = y
    }
}
