pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Palette loaded from the theme system (themes/apply-palette.sh writes
    // ~/.cache/theme-colors/quickshell.json). Empty object -> Mocha defaults.
    property var pal: ({})

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.cache/theme-colors/quickshell.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.loadPalette()
        onLoadFailed: root.pal = {}
    }

    function loadPalette() {
        try {
            const parsed = JSON.parse(paletteFile.text());
            root.pal = (parsed && typeof parsed === "object") ? parsed : {};
        } catch (e) {
            console.log("Theme: ignoring invalid palette json:", e);
            root.pal = {};
        }
    }

    function c(name, fallback) {
        const v = root.pal[name];
        return (typeof v === "string") ? v : fallback;
    }

    // Catppuccin Mocha defaults, overridden by the generated palette
    readonly property color base:        c("base",      "#1e1e2e")
    readonly property color mantle:      c("mantle",    "#181825")
    readonly property color crust:       c("crust",     "#11111b")
    readonly property color text:        c("text",      "#cdd6f4")
    readonly property color subtext0:    c("subtext0",  "#a6adc8")
    readonly property color subtext1:    c("subtext1",  "#bac2de")
    readonly property color surface0:    c("surface0",  "#313244")
    readonly property color surface1:    c("surface1",  "#45475a")
    readonly property color surface2:    c("surface2",  "#585b70")
    readonly property color overlay0:    c("overlay0",  "#6c7086")
    readonly property color blue:        c("blue",      "#89b4fa")
    readonly property color lavender:    c("lavender",  "#b4befe")
    readonly property color sapphire:    c("sapphire",  "#74c7ec")
    readonly property color sky:         c("sky",       "#89dceb")
    readonly property color teal:        c("teal",      "#94e2d5")
    readonly property color green:       c("green",     "#a6e3a1")
    readonly property color yellow:      c("yellow",    "#f9e2af")
    readonly property color peach:       c("peach",     "#fab387")
    readonly property color maroon:      c("maroon",    "#eba0ac")
    readonly property color red:         c("red",       "#f38ba8")
    readonly property color mauve:       c("mauve",     "#cba6f7")
    readonly property color pink:        c("pink",      "#f5c2e7")
    readonly property color flamingo:    c("flamingo",  "#f2cdcd")
    readonly property color rosewater:   c("rosewater", "#f5e0dc")

    readonly property color barBackground: Qt.alpha(base, 0.30)
    readonly property color borderColor:   Qt.alpha(subtext1, 0.20)

    // Fonts
    readonly property string fontFamily: "JetBrains Mono"

    // Shared metrics
    readonly property int moduleRadius: 10
    readonly property int panelRadius:  16
    readonly property int pillRadius:   20
    readonly property int osdRadius:    99

    readonly property int moduleMargin: 4
    readonly property int modulePadding: 5
    readonly property int groupPadding: 10

    // Per-widget accents
    readonly property color cpuColor:    sapphire
    readonly property color memoryColor: mauve
    readonly property color tempColor:   peach
    readonly property color clockColor:  blue
    readonly property color powerColor:  red
    readonly property color toolsToggle: sapphire
    readonly property color wsActiveBg:  mauve
    readonly property color wsActiveFg:  base
    readonly property color ytmColor:    lavender
    readonly property color aiColor:     teal
}
