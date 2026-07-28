import { createComputed, createState, For } from "ags"
import { Gtk } from "ags/gtk4"
import Pango from "gi://Pango"
import {
    cities,
    tick,
    zoneInfo,
    addCity,
    removeCity,
    search,
    type CityRow,
    type SearchEntry,
} from "./WorldClockService"

export default function WorldClock() {
    const [adding, setAdding] = createState(false)
    const [query, setQuery] = createState("")
    let entry: Gtk.Entry | null = null

    const rows = createComputed((): CityRow[] => {
        tick() // re-render every service tick
        return cities().map(c => ({ ...c, ...zoneInfo(c.tz) }))
    })

    const suggestions = createComputed((): SearchEntry[] =>
        adding() ? search(query()) : [],
    )

    function finishAdd(e: SearchEntry) {
        addCity(e.tz, e.label)
        setAdding(false)
        setQuery("")
        entry!.set_text("")
    }

    function toggleAdding() {
        const next = !adding.peek()
        setAdding(next)
        setQuery("")
        entry!.set_text("")
        if (next) entry!.grab_focus()
    }

    return (
        <Gtk.Box class="world-clock" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
            <Gtk.Box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
                <Gtk.Label class="wc-title" label="World Clock" halign={Gtk.Align.START} hexpand />
                <Gtk.Button class="wc-add" onClicked={toggleAdding}>
                    <Gtk.Image iconName={adding.as(a => a ? "window-close-symbolic" : "list-add-symbolic")} />
                </Gtk.Button>
            </Gtk.Box>

            <Gtk.Revealer
                revealChild={adding}
                transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
            >
                <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    <Gtk.Entry
                        $={self => { entry = self }}
                        placeholderText="Search city or timezone..."
                        onChanged={self => setQuery(self.text)}
                        onActivate={() => {
                            const matches = suggestions.peek()
                            if (matches.length > 0) finishAdd(matches[0])
                        }}
                    />
                    <For each={suggestions}>
                        {(s: SearchEntry) => (
                            <Gtk.Button class="wc-suggestion" onClicked={() => finishAdd(s)}>
                                <Gtk.Label
                                    label={s.display}
                                    halign={Gtk.Align.START}
                                    ellipsize={Pango.EllipsizeMode.END}
                                />
                            </Gtk.Button>
                        )}
                    </For>
                </Gtk.Box>
            </Gtk.Revealer>

            <For each={rows}>
                {(row: CityRow) => (
                    <Gtk.Box class="wc-row" orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
                        <Gtk.Label
                            class="wc-city"
                            label={row.label}
                            halign={Gtk.Align.START}
                            hexpand
                            ellipsize={Pango.EllipsizeMode.END}
                        />
                        <Gtk.Label class="wc-meta" label={`${row.day} · ${row.offset}`} />
                        <Gtk.Label class="wc-time" label={row.time} />
                        <Gtk.Button
                            class="wc-remove"
                            onClicked={() => removeCity(row.tz, row.label)}
                        >
                            <Gtk.Image iconName="window-close-symbolic" pixelSize={10} />
                        </Gtk.Button>
                    </Gtk.Box>
                )}
            </For>
        </Gtk.Box>
    )
}
