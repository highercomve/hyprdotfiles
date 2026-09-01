# Quickshell plugins

A plugin is a folder `plugins/<id>/` declared in `../plugins.json`:

```json
"plugins": { "<id>": { "enabled": true, "kinds": [...], "settings": {...} } }
```

Entry files by convention, one per kind:

- `service` -> `Service.qml` — headless Item, mounted by PluginHost, exposed
  as `PluginRegistry.services["<id>"]`.
- `barWidget` -> `BarWidget.qml` — Item placed in the bar; list the id under
  `bar.left|center|right` in plugins.json (list order = display order).
- `panel` -> `Panel.qml` — a PanelPopup window; open/close with
  `Panels.toggle(pluginId)` / `Panels.isOpen(pluginId)`.

Plugin roots may declare `pluginId`, `settings`, `service` — the host injects
them (duck-typed; declare only what you need). Shared code via relative
imports: `import "../../Theme"`, `"../../Services"`, `"../../Panels"`.

Enable/disable = edit plugins.json + restart the shell (`../launch.sh`).
QML is NOT hot-reloaded.

A plugin with extra local components (beyond the conventional entry
files) must list them in a local `qmldir` (e.g. `UsageBar 1.0 UsageBar.qml`)
— implicit same-directory resolution does not work through the qs:// scheme.
