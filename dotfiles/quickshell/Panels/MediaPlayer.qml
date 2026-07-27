import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

import "../Services"
import "../Theme"

Rectangle {
    color: "transparent"
    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Loader {
            id: playerLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: Ytm.hasTrack ? youtubeComponent : mprisComponent
        }
    }

    Component {
        id: mprisComponent
        MprisPlayerWidget {
            anchors.fill: parent
        }
    }

    Component {
        id: youtubeComponent
        YouTubePlayerWidget {
            anchors.fill: parent
        }
    }
}
