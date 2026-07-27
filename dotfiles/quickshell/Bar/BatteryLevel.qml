import Quickshell
import Quickshell.Services.UPower
import QtQuick

import "../Theme"

Rectangle {
    color: "transparent"
    implicitWidth: batteryIcon.visible ? 50 : 0
    implicitHeight: 30
    visible: UPower.displayDevice?.isLaptopBattery

    Text {
        id: batteryIcon
        anchors.centerIn: parent
        text: batteryGlyph(UPower.displayDevice?.iconName || "") + " " + Math.round((UPower.displayDevice?.percentage || 0) * 100) + "%"
        color: UPower.displayDevice?.state === UPowerDeviceState.Charging ? Theme.green
             : UPower.displayDevice?.percentage <= 0.15 ? Theme.red
             : Theme.green
        font.family: "Font Awesome 7 Free Solid"
        font.pixelSize: 11
    }

    function batteryGlyph(iconName) {
        if (iconName.includes("empty")) return ""
        if (iconName.includes("caution")) return ""
        if (iconName.includes("low")) return ""
        if (iconName.includes("good")) return ""
        if (iconName.includes("full")) return ""
        return ""
    }
}
