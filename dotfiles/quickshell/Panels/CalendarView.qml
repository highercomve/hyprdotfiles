import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../Theme"

Rectangle {
    id: root
    color: "transparent"

    property int displayMonth: new Date().getMonth()
    property int displayYear: new Date().getFullYear()

    // Workaround for QTBUG-79906: MonthGrid's model.today is computed with
    // UTC-based date math and marks the wrong day in UTC-negative timezones.
    readonly property date today: new Date()

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
                id: dayCell

                readonly property bool isToday: model.year === root.today.getFullYear()
                                                && model.month === root.today.getMonth()
                                                && model.day === root.today.getDate()

                width: 40
                height: 32
                radius: 6
                color: dayCell.isToday ? Theme.blue : (model.month === calendarMonth.month ? "transparent" : Theme.surface0)

                Text {
                    anchors.centerIn: parent
                    text: model.day
                    color: dayCell.isToday ? Theme.base : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: dayCell.isToday
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
