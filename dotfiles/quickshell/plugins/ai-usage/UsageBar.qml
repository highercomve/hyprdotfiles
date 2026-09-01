import QtQuick
import QtQuick.Layouts

import "../../Theme"

// One limit row: label + percent, a track/fill bar, and a reset countdown.
ColumnLayout {
    id: bar

    property string label: ""
    property var percent: null     // 0-100, or null when unknown
    property string resetsAt: ""   // ISO 8601, or empty
    property date now: new Date()  // ticked by the caller's SystemClock

    readonly property bool known: typeof percent === "number"
    readonly property real frac: known ? Math.min(1, Math.max(0, percent / 100)) : 0
    readonly property color fillColor: !known ? Theme.overlay0
        : percent >= 90 ? Theme.red
        : percent >= 70 ? Theme.yellow
        : Theme.blue

    spacing: 3

    function resetText() {
        if (!resetsAt) return ""
        const t = new Date(resetsAt).getTime()
        if (isNaN(t)) return ""
        let mins = Math.round((t - now.getTime()) / 60000)
        if (mins <= 0) return "resets now"
        const d = Math.floor(mins / 1440)
        mins -= d * 1440
        const h = Math.floor(mins / 60)
        const m = mins % 60
        return "resets in " + (d > 0 ? d + "d " : "") + (h > 0 ? h + "h " : "") + m + "m"
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: bar.label
            color: Theme.subtext1
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Item { Layout.fillWidth: true }

        Text {
            text: bar.known ? Math.round(bar.percent) + "%" : "—"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 6
        radius: 99
        color: Theme.surface0

        Rectangle {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: parent.width * bar.frac
            height: parent.height
            radius: 99
            color: bar.fillColor

            Behavior on width {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
        }
    }

    Text {
        text: bar.resetText()
        color: Theme.subtext0
        font.family: Theme.fontFamily
        font.pixelSize: 10
        visible: text !== ""
    }
}
