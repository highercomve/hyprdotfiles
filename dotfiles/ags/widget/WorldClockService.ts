import GLib from "gi://GLib"
import { createState } from "ags"
import { readFileAsync, writeFileAsync } from "ags/file"
import { execAsync } from "ags/process"

export type City = { tz: string; label: string }
export type CityRow = City & { time: string; day: string; offset: string }
export type SearchEntry = {
    tz: string
    label: string
    display: string
    nameKey: string
    key: string
    pop: number
}

const STATE_FILE = `${GLib.get_user_state_dir()}/ags/worldclocks.json`
const CITIES_TSV = `${GLib.get_user_config_dir()}/ags/cities.tsv`

const DEFAULT_CITIES: City[] = [
    { tz: "America/New_York", label: "New York" },
    { tz: "Europe/Madrid", label: "Madrid" },
    { tz: "Asia/Tokyo", label: "Tokyo" },
]

const WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

const [cities, setCities] = createState<City[]>(DEFAULT_CITIES)
const [searchEntries, setSearchEntries] = createState<SearchEntry[]>([])
const [tick, setTick] = createState(0)

export { cities, searchEntries, tick }

// GLib computes zone times from tzdata directly; no subprocess needed
export function zoneInfo(tz: string): { time: string; day: string; offset: string } {
    const zone = GLib.TimeZone.new_identifier(tz)
    if (!zone) return { time: "--:--", day: "", offset: "" }
    const now = GLib.DateTime.new_now(zone)!
    const local = GLib.DateTime.new_now_local()!

    const h24 = now.get_hour()
    const h12 = h24 % 12 === 0 ? 12 : h24 % 12
    const time = `${h12}:${String(now.get_minute()).padStart(2, "0")} ${h24 < 12 ? "AM" : "PM"}`

    // get_utc_offset is in microseconds
    const diffMin = (now.get_utc_offset() - local.get_utc_offset()) / 60_000_000
    let offset = "local"
    if (diffMin !== 0) {
        const hours = diffMin / 60
        offset = (diffMin > 0 ? "+" : "") + (Number.isInteger(hours) ? hours : hours.toFixed(1)) + "h"
    }

    return { time, day: WEEKDAYS[now.get_day_of_week() - 1], offset }
}

export function addCity(tz: string, label?: string) {
    const l = label || tz.split("/").pop()!.replace(/_/g, " ")
    setCities(prev => {
        if (prev.some(c => c.tz === tz && c.label === l)) return prev
        return [...prev, { tz, label: l }]
    })
    save()
}

export function removeCity(tz: string, label: string) {
    setCities(prev => prev.filter(c => !(c.tz === tz && c.label === label)))
    save()
}

function save() {
    writeFileAsync(STATE_FILE, JSON.stringify({ cities: cities.peek() }, null, 2))
        .catch(err => console.error("WorldClock: failed to save state:", err))
}

async function loadState() {
    try {
        const parsed = JSON.parse(await readFileAsync(STATE_FILE))
        if (Array.isArray(parsed?.cities)) setCities(parsed.cities)
    } catch {
        // First run: keep defaults and create the file
        save()
    }
}

// Search index: cities (GeoNames, cities.tsv) + tzdata zones/countries,
// so "houston", "germany", and "Europe/Berlin" all match
async function buildSearchIndex() {
    try {
        const [iso, zone, tzListOut, citiesTsv] = await Promise.all([
            readFileAsync("/usr/share/zoneinfo/iso3166.tab"),
            readFileAsync("/usr/share/zoneinfo/zone1970.tab"),
            execAsync(["timedatectl", "list-timezones", "--no-pager"]),
            readFileAsync(CITIES_TSV),
        ])

        const countryByCode: Record<string, string> = {}
        for (const line of iso.split("\n")) {
            if (!line || line[0] === "#") continue
            const f = line.split("\t")
            if (f.length === 2) countryByCode[f[0]] = f[1]
        }

        const metaByTz: Record<string, { codes: string[]; comment: string }> = {}
        for (const line of zone.split("\n")) {
            if (!line || line[0] === "#") continue
            const f = line.split("\t")
            if (f.length >= 3) metaByTz[f[2]] = { codes: f[0].split(","), comment: f[3] || "" }
        }

        const cityEntries: SearchEntry[] = []
        for (const line of citiesTsv.split("\n")) {
            if (!line || line[0] === "#") continue
            const f = line.split("\t")
            if (f.length < 5) continue
            const [name, ascii, cc, tz, pop] = f
            const country = countryByCode[cc] || cc
            cityEntries.push({
                tz,
                label: name,
                display: `${name} · ${country}`,
                nameKey: `${name} ${ascii}`.toLowerCase(),
                key: `${name} ${ascii} ${country}`.toLowerCase(),
                pop: Number(pop),
            })
        }

        const tzEntries: SearchEntry[] = tzListOut
            .trim()
            .split("\n")
            .filter(tz => tz.length > 0)
            .map(tz => {
                const meta = metaByTz[tz]
                const names = meta ? meta.codes.map(c => countryByCode[c] || c) : []
                const pretty = tz.replace(/_/g, " ")
                return {
                    tz,
                    label: tz.split("/").pop()!.replace(/_/g, " "),
                    display: pretty + (names.length ? " · " + names.join(", ") : ""),
                    nameKey: pretty.toLowerCase(),
                    key: `${pretty} ${names.join(" ")} ${meta ? meta.comment : ""}`.toLowerCase(),
                    pop: 0,
                }
            })

        setSearchEntries([...cityEntries, ...tzEntries])
    } catch (err) {
        console.error("WorldClock: failed to build search index:", err)
    }
}

export function search(query: string): SearchEntry[] {
    const q = query.trim().toLowerCase()
    if (q.length < 2) return []
    // Word-prefix name matches beat country/region/substring matches;
    // population breaks ties
    const t = (e: SearchEntry) => (e.nameKey.startsWith(q) || e.nameKey.includes(" " + q)) ? 0 : 1
    return searchEntries
        .peek()
        .filter(e => e.key.includes(q))
        .sort((a, b) => (t(a) - t(b)) || (b.pop - a.pop))
        .slice(0, 4)
}

let timerId: number | null = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 10, () => {
    setTick(t => t + 1)
    return GLib.SOURCE_CONTINUE
})

export function cleanup() {
    if (timerId) {
        GLib.source_remove(timerId)
        timerId = null
    }
}

void loadState()
void buildSearchIndex()
