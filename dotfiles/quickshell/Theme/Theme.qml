pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Catppuccin Mocha palette
    readonly property color base:        "#1e1e2e"
    readonly property color mantle:      "#181825"
    readonly property color crust:       "#11111b"
    readonly property color text:        "#cdd6f4"
    readonly property color subtext0:    "#a6adc8"
    readonly property color subtext1:    "#bac2de"
    readonly property color surface0:    "#313244"
    readonly property color surface1:    "#45475a"
    readonly property color surface2:    "#585b70"
    readonly property color overlay0:    "#6c7086"
    readonly property color blue:        "#89b4fa"
    readonly property color lavender:    "#b4befe"
    readonly property color sapphire:    "#74c7ec"
    readonly property color sky:         "#89dceb"
    readonly property color teal:        "#94e2d5"
    readonly property color green:       "#a6e3a1"
    readonly property color yellow:      "#f9e2af"
    readonly property color peach:       "#fab387"
    readonly property color maroon:      "#eba0ac"
    readonly property color red:         "#f38ba8"
    readonly property color mauve:       "#cba6f7"
    readonly property color pink:        "#f5c2e7"
    readonly property color flamingo:    "#f2cdcd"
    readonly property color rosewater:   "#f5e0dc"

    readonly property color barBackground: "#4d1e1e2e"   // 30% alpha base
    readonly property color borderColor:   "#33bac2de"   // 20% alpha subtext1

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
}
