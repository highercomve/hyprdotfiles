-- -----------------------------------------------------
-- Window rules (migrated from conf/windowrule.conf)
-- -----------------------------------------------------

hl.window_rule({
    name  = "windowrule-1",
    match = { class = "^(pavucontrol)$" },
    float = true,
})

hl.window_rule({
    name  = "windowrule-2",
    match = { class = "^(blueman-manager)$" },
    float = true,
})

hl.window_rule({
    name  = "windowrule-3",
    match = { title = "^(nmtui-applet)$" },
    float = true,
})

hl.window_rule({
    name  = "windowrule-4",
    match = { title = "^(qalculate-gtk)$" },
    float = true,
})

hl.window_rule({
    name   = "windowrule-5",
    match  = { class = "^(dotfiles-floating)$" },
    float  = true,
    size   = { "(monitor_w*0.8)", "(monitor_h*0.8)" },
    center = true,
})

hl.window_rule({
    name   = "windowrule-6",
    match  = { class = "^(dotfiles-floating-sm)$" },
    float  = true,
    center = true,
    size   = { "(monitor_w*0.4)", "(monitor_h*0.8)" },
})

hl.window_rule({
    name  = "windowrule-7",
    match = { title = "^(Microsoft Teams)$" },
    tile  = true,
})

-- Browser Picture in Picture
hl.window_rule({
    name  = "windowrule-8",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
    move  = { "((monitor_w*0.695))", "((monitor_h*0.04))" },
})

-- idleinhibit: fullscreen windows keep the screen awake.
-- NOTE: the old .conf rule also had "fullscreen = on" as an EFFECT next to a
-- catch-all class regex, which in the new engine would force-fullscreen
-- nearly every window — clearly not the intent, so only the idle_inhibit
-- part is kept here.
hl.window_rule({
    name         = "windowrule-9",
    match        = { class = ".*" },
    idle_inhibit = "fullscreen",
})

-- xwayland related rules
-- When moving objects in resolve a large border is produced; this rule
-- prevents that and serves as a template for any problematic xwayland apps.
hl.window_rule({
    name    = "windowrule-10",
    match   = { class = "^(\\bresolve\\b)$", xwayland = true },
    no_blur = true,
})

-- A general no_blur for all xwayland apps can have other consequences (it
-- impacted EMACS for one user), so it stays disabled; kept for reference:
-- hl.window_rule({ name = "xwayland-noblur", match = { xwayland = true }, no_blur = true })

hl.window_rule({
    name  = "windowrule-11",
    match = { class = "^(org.gnome.Calendar)$" },
    float = true,
    size  = { 350, 300 },
})

hl.window_rule({
    name  = "windowrule-12",
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    float = true,
    size  = { 700, 500 },
    move  = { "((monitor_w*1)-900)", "(60)" },
})

-- GhostPen overlay — floating, centered, pinned so it follows the active
-- workspace (without pin, show() restores the hidden window to its original
-- workspace, so the overlay stops appearing once you switch workspaces).
-- Title-scoped so it does NOT center the bottom overlays below.
hl.window_rule({
    name   = "ghostpen",
    match  = {
        class = "^([Gg]hostpen)$",
        title = "^(GhostPen|GhostPen Settings|GhostPen Playground)$",
    },
    float  = true,
    center = true,
    pin    = true,
})

-- GhostPen bottom overlays — captions bar (900×170) and dictation pill
-- (520×200) dock bottom-center, ~6% above the bottom edge (mirrors the
-- app's own placement).
hl.window_rule({
    name  = "ghostpen-captions",
    match = { class = "^([Gg]hostpen)$", title = "^(GhostPen Captions)$" },
    float = true,
    pin   = true,
    move  = { "(((monitor_w)-900)/2)", "(((monitor_h)*0.94)-170)" },
})

hl.window_rule({
    name  = "ghostpen-dictation",
    match = { class = "^([Gg]hostpen)$", title = "^(GhostPen Dictation)$" },
    float = true,
    pin   = true,
    move  = { "(((monitor_w)-520)/2)", "(((monitor_h)*0.94)-200)" },
})
