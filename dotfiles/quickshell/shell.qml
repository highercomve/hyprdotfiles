//@ pragma UseQApplication
import Quickshell
import QtQuick

import "Bar"
import "Panels"
import "Osd"
import "NotificationPopups"

ShellRoot {
    PluginHost {}
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    Variants {
        model: Quickshell.screens
        delegate: VolumeOsd {}
    }

    Variants {
        model: Quickshell.screens
        delegate: NotificationPopups {}
    }

    ControlPanel {}
    CenterPopup {}
}
