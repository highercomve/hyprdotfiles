pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

PanelPopup {
    id: aiPopup

    popupWidth: 380
    popupHeight: mainCol.implicitHeight + 40
    marginTop: 40
    marginRight: 5
    alignRight: true

    visible: Panels.aiUsageOpen
    onVisibleChanged: if (visible) AiUsage.refreshIfStale()
    onCloseRequested: Panels.closeAiUsage()

    panelContent: Rectangle {
        anchors.fill: parent
        color: Theme.base
        radius: Theme.panelRadius
        border.color: Theme.surface1
        border.width: 1

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        ColumnLayout {
            id: mainCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 20
            }
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "AI Usage"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: {
                        if (!AiUsage.updatedAt) return ""
                        const t = new Date(AiUsage.updatedAt).getTime()
                        if (isNaN(t)) return ""
                        const mins = Math.round((clock.date.getTime() - t) / 60000)
                        return mins <= 0 ? "just now" : mins + "m ago"
                    }
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                Text {
                    id: refreshIcon
                    text: "" // arrows-rotate
                    color: refreshMouse.containsMouse ? Theme.text : Theme.subtext0
                    font.family: "Font Awesome 7 Free Solid"
                    font.pixelSize: 13

                    RotationAnimation on rotation {
                        running: AiUsage.refreshing
                        from: 0
                        to: 360
                        duration: 800
                        loops: Animation.Infinite
                        onStopped: refreshIcon.rotation = 0
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AiUsage.refresh()
                    }
                }
            }

            Repeater {
                model: AiUsage.providers

                Rectangle {
                    id: card

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: cardCol.implicitHeight + 24
                    color: Theme.mantle
                    radius: 12
                    opacity: modelData.stale ? 0.6 : 1

                    ColumnLayout {
                        id: cardCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 12
                        }
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: card.modelData.name
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Rectangle {
                                visible: !!card.modelData.plan
                                implicitWidth: planText.implicitWidth + 12
                                implicitHeight: planText.implicitHeight + 4
                                radius: 99
                                color: Theme.surface0

                                Text {
                                    id: planText
                                    anchors.centerIn: parent
                                    text: card.modelData.plan || ""
                                    color: Theme.subtext1
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                visible: card.modelData.stale === true
                                text: "stale"
                                color: Theme.yellow
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            visible: !!card.modelData.error
                            Layout.fillWidth: true
                            text: card.modelData.error || ""
                            color: Theme.maroon
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        Repeater {
                            model: card.modelData.limits || []

                            UsageBar {
                                required property var modelData

                                Layout.fillWidth: true
                                label: modelData.label
                                percent: modelData.percent
                                resetsAt: modelData.resetsAt || ""
                                now: clock.date
                            }
                        }
                    }
                }
            }
        }
    }
}
