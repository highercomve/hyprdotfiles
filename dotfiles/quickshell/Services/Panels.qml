pragma Singleton
import Quickshell

Singleton {
    property bool controlPanelOpen: false
    property bool centerPopupOpen: false
    property string controlPanelPage: "main"

    // Generic keyed panel state for plugins (see PluginHost/plugins.json).
    // Replaced-on-write so isOpen() bindings re-evaluate.
    property var openPanels: ({})

    function isOpen(id) { return openPanels[id] === true }
    function open(id) { _setOpen(id, true) }
    function close(id) { _setOpen(id, false) }
    function toggle(id) { _setOpen(id, openPanels[id] !== true) }
    function _setOpen(id, v) {
        const m = Object.assign({}, openPanels)
        m[id] = v
        openPanels = m
    }

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
