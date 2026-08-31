pragma Singleton
import Quickshell

Singleton {
    property bool controlPanelOpen: false
    property bool centerPopupOpen: false
    property bool aiUsageOpen: false
    property string controlPanelPage: "main"

    function toggleControlPanel() {
        controlPanelOpen = !controlPanelOpen
        if (controlPanelOpen) controlPanelPage = "main"
    }

    function openControlPanel() {
        controlPanelOpen = true
        controlPanelPage = "main"
    }

    function closeControlPanel() {
        controlPanelOpen = false
    }

    function switchControlPanelPage(page) {
        controlPanelPage = page
    }

    function toggleAiUsage() {
        aiUsageOpen = !aiUsageOpen
    }

    function closeAiUsage() {
        aiUsageOpen = false
    }

    function toggleCenterPopup() {
        centerPopupOpen = !centerPopupOpen
    }

    function openCenterPopup() {
        centerPopupOpen = true
    }

    function closeCenterPopup() {
        centerPopupOpen = false
    }
}
