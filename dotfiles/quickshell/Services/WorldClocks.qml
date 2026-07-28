pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // [{ tz: "Asia/Tokyo", label: "Tokyo" }, ...]
    property var cities: store.cities
    // tz -> { time: "5:04 PM", day: "Tue", offset: "+9h" }
    property var times: ({})
    property var allTimezones: []
    // [{ tz, label, display, key, pop }] — cities (GeoNames) + timezones (tzdata)
    property var searchEntries: []
    property var _countryByCode: null
    property var _metaByTz: null
    property var _cities: null

    FileView {
        id: stateFile
        path: Quickshell.statePath("worldclocks.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) writeAdapter()
        }

        adapter: JsonAdapter {
            id: store
            property var cities: [
                { tz: "America/New_York", label: "New York" },
                { tz: "Europe/Madrid", label: "Madrid" },
                { tz: "Asia/Tokyo", label: "Tokyo" }
            ]
            onCitiesChanged: root.refresh()
        }
    }

    SystemClock {
        precision: SystemClock.Minutes
        onDateChanged: root.refresh()
    }

    Process {
        id: timesProc
        stdout: StdioCollector { onStreamFinished: root.handleTimes(text) }
    }

    Process {
        id: tzListProc
        command: ["timedatectl", "list-timezones", "--no-pager"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.allTimezones = text.trim().split("\n").filter(t => t.length > 0)
                root.buildSearchIndex()
            }
        }
    }

    // Country names (iso3166.tab) + country-to-zone map (zone1970.tab) so the
    // search box matches "Germany", not just "Berlin"
    Process {
        id: metaProc
        command: ["cat", "/usr/share/zoneinfo/iso3166.tab", "/usr/share/zoneinfo/zone1970.tab"]
        stdout: StdioCollector { onStreamFinished: root.handleMeta(text) }
    }

    // City-to-timezone data so searching "houston" works (see Assets/cities.tsv)
    Process {
        id: citiesProc
        command: ["cat", Quickshell.shellDir + "/Assets/cities.tsv"]
        stdout: StdioCollector { onStreamFinished: root.handleCities(text) }
    }

    Component.onCompleted: {
        tzListProc.running = true
        metaProc.running = true
        citiesProc.running = true
        refresh()
    }

    function handleCities(output) {
        const cities = []
        for (const line of output.split("\n")) {
            if (!line || line[0] === "#") continue
            const f = line.split("\t")
            if (f.length < 5) continue
            cities.push({ name: f[0], ascii: f[1], cc: f[2], tz: f[3], pop: Number(f[4]) })
        }
        _cities = cities
        buildSearchIndex()
    }

    function handleMeta(output) {
        const countries = {}
        const meta = {}
        for (const line of output.split("\n")) {
            if (!line || line[0] === "#") continue
            const f = line.split("\t")
            if (f.length === 2) countries[f[0]] = f[1]
            else if (f.length >= 3) meta[f[2]] = { codes: f[0].split(","), comment: f[3] || "" }
        }
        _countryByCode = countries
        _metaByTz = meta
        buildSearchIndex()
    }

    function buildSearchIndex() {
        if (allTimezones.length === 0 || !_metaByTz || !_cities) return
        const cityEntries = _cities.map(c => {
            const country = _countryByCode[c.cc] || c.cc
            return {
                tz: c.tz,
                label: c.name,
                display: c.name + " · " + country,
                nameKey: (c.name + " " + c.ascii).toLowerCase(),
                key: (c.name + " " + c.ascii + " " + country).toLowerCase(),
                pop: c.pop
            }
        })
        const tzEntries = allTimezones.map(tz => {
            const meta = _metaByTz[tz]
            const names = meta ? meta.codes.map(c => _countryByCode[c] || c) : []
            const pretty = tz.replace(/_/g, " ")
            return {
                tz: tz,
                label: tz.split("/").pop().replace(/_/g, " "),
                display: pretty + (names.length ? " · " + names.join(", ") : ""),
                nameKey: pretty.toLowerCase(),
                key: (pretty + " " + names.join(" ") + " " + (meta ? meta.comment : "")).toLowerCase(),
                pop: 0
            }
        })
        searchEntries = cityEntries.concat(tzEntries)
    }

    function refresh() {
        const list = store.cities
        if (!list || list.length === 0) {
            times = {}
            return
        }
        // tzdata does the real work; one line per zone: tz|time|weekday|utcoffset
        // LC_TIME=C because %p is empty in some locales (e.g. es_ES)
        const script = 'for tz in "$@"; do TZ="$tz" LC_TIME=C date "+$tz|%l:%M %p|%a|%z"; done'
        timesProc.command = ["bash", "-c", script, "--"].concat(list.map(c => c.tz))
        timesProc.running = true
    }

    function handleTimes(output) {
        const localMin = -(new Date().getTimezoneOffset())
        const map = {}
        for (const line of output.trim().split("\n")) {
            const parts = line.split("|")
            if (parts.length !== 4) continue
            const remoteMin = parseUtcOffset(parts[3])
            map[parts[0]] = {
                time: parts[1].trim(),
                day: parts[2],
                offset: formatOffset(remoteMin - localMin)
            }
        }
        times = map
    }

    function parseUtcOffset(z) {
        // "+0530" -> 330
        const sign = z[0] === "-" ? -1 : 1
        return sign * (parseInt(z.slice(1, 3), 10) * 60 + parseInt(z.slice(3, 5), 10))
    }

    function formatOffset(diffMin) {
        if (diffMin === 0) return "local"
        const hours = diffMin / 60
        const text = Number.isInteger(hours) ? hours.toString() : hours.toFixed(1)
        return (diffMin > 0 ? "+" : "") + text + "h"
    }

    function addCity(tz, label) {
        if (!label) label = tz.split("/").pop().replace(/_/g, " ")
        if (store.cities.some(c => c.tz === tz && c.label === label)) return
        store.cities = store.cities.concat([{ tz: tz, label: label }])
    }

    function removeCity(tz) {
        store.cities = store.cities.filter(c => c.tz !== tz)
    }
}
