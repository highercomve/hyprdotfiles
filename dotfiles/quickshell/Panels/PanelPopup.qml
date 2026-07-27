import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: popupWindow

    signal closeRequested()

    property int popupWidth: 400
    property int popupHeight: 800
    property int marginTop: 40
    property int marginRight: 5
    property int marginBottom: 0
    property int marginLeft: 0
    property bool alignRight: true
    property bool alignCenter: false
    // Height of the top bar: popups emerge from underneath it, never on top of it
    property int barHeight: 38

    visible: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    // Fullscreen overlay: the backdrop catches outside clicks (like the AGS popup
    // windows); the panel content is a fixed-size container aligned inside it.
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: popupWindow.closeRequested()
    }

    // Clip region starting below the bar so the slide-in animation appears to
    // come out from under the bar instead of passing over it.
    Item {
        id: clipArea
        anchors.fill: parent
        anchors.topMargin: popupWindow.barHeight
        clip: true

        Rectangle {
            id: contentContainer
            width: popupWindow.popupWidth
            height: popupWindow.popupHeight
            color: "transparent"

            anchors.right: (!popupWindow.alignCenter && popupWindow.alignRight) ? parent.right : undefined
            anchors.rightMargin: popupWindow.marginRight
            anchors.left: (!popupWindow.alignCenter && !popupWindow.alignRight) ? parent.left : undefined
            anchors.leftMargin: popupWindow.marginLeft
            anchors.horizontalCenter: popupWindow.alignCenter ? parent.horizontalCenter : undefined

            // Slide in from under the bar to the final position when opening
            y: popupWindow.visible ? Math.max(0, popupWindow.marginTop - popupWindow.barHeight) : -height
            Behavior on y {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            // Swallow clicks that land inside the panel but miss its controls,
            // so they don't fall through to the closing backdrop.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }
        }
    }

    default property alias panelContent: contentContainer.data

    Item {
        anchors.fill: parent
        focus: popupWindow.visible
        Keys.onEscapePressed: popupWindow.closeRequested()
    }
}
