import { createBinding, For } from "ags"
import { Gtk } from "ags/gtk4"
import YouTubeService from "./YouTubeService"
import Pango from "gi://Pango"

export default function YouTubeSearch() {
    const filters = [
        { label: "Songs", value: "songs" },
        { label: "Artists", value: "artists" },
        { label: "Albums", value: "albums" },
        { label: "Playlists", value: "playlists" },
    ]

    const filterBinding = createBinding(YouTubeService, "searchFilter")

    return (
        <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={12} css="margin-top: 16px;">
            {/* Search Bar */}
            <Gtk.Box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
                <Gtk.Image iconName="system-search-symbolic" />
                <Gtk.Entry
                    hexpand
                    placeholderText="Search YouTube Music..."
                    onChanged={(self) => YouTubeService.searchQuery = self.text}
                    onActivate={() => YouTubeService.search(YouTubeService.searchQuery, YouTubeService.searchFilter)}
                    css="background-color: rgba(255,255,255,0.05); color: #cdd6f4; border: none; border-radius: 8px; padding: 8px;"
                />
            </Gtk.Box>

            {/* Filters */}
            <Gtk.Box orientation={Gtk.Orientation.HORIZONTAL} spacing={4} halign={Gtk.Align.CENTER}>
                {filters.map(f => (
                    <Gtk.Button 
                        onClicked={() => {
                            YouTubeService.searchFilter = f.value
                            YouTubeService.search(YouTubeService.searchQuery, f.value)
                        }}
                        css={filterBinding.as(curr => `
                            font-size: 0.8em; 
                            padding: 4px 12px; 
                            border-radius: 12px; 
                            transition: all 0.2s;
                            background: ${curr === f.value ? "#89b4fa" : "rgba(255,255,255,0.05)"};
                            color: ${curr === f.value ? "#1e1e2e" : "#cdd6f4"};
                        `)}
                    >
                        <Gtk.Label label={f.label} />
                    </Gtk.Button>
                ))}
            </Gtk.Box>

            {/* Results */}
            <Gtk.ScrolledWindow
                hscrollbarPolicy={Gtk.PolicyType.NEVER}
                vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                css="min-height: 250px; max-height: 400px;"
            >
                <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    <Gtk.Label
                        label="Searching..."
                        css="padding: 20px; color: #6c7086;"
                        visible={createBinding(YouTubeService, "isSearching")}
                    />
                    <For each={createBinding(YouTubeService, "searchResults")}>
                        {((res: any) => (
                            <Gtk.Button
                                onClicked={() => {
                                    if (res.type === "song" || res.type === "video") {
                                        YouTubeService.play(res.id, res.name, res.artist)
                                    } else {
                                        YouTubeService.searchQuery = res.name
                                        YouTubeService.searchFilter = "songs"
                                        YouTubeService.search(res.name, "songs")
                                    }
                                }}
                                css="background-color: transparent; border: none; border-radius: 8px; padding: 8px; text-align: left;"
                            >
                                <Gtk.Box spacing={12}>
                                    <Gtk.Box 
                                        css={`
                                            min-width: 44px; min-height: 44px; 
                                            border-radius: ${res.type === "artist" ? "50%" : "6px"};
                                            background-image: url('${res.thumbnail}');
                                            background-size: cover;
                                            background-position: center;
                                            background-color: #313244;
                                        `} 
                                    />
                                    <Gtk.Box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER} hexpand>
                                        <Gtk.Label 
                                            label={res.name || "Unknown"} 
                                            halign={Gtk.Align.START} 
                                            css="font-weight: bold; color: #cdd6f4;" 
                                            ellipsize={Pango.EllipsizeMode.END} 
                                        />
                                        <Gtk.Label 
                                            label={`${res.artist || ""} • ${res.type || ""}`} 
                                            halign={Gtk.Align.START} 
                                            css="font-size: 0.8em; color: #a6adc8;" 
                                        />
                                    </Gtk.Box>
                                    <Gtk.Button 
                                        onClicked={() => YouTubeService.startRadio(res.id)}
                                        css="background: transparent; border: none; color: #a6adc8;"
                                        tooltipText="Start Radio"
                                        visible={res.type === "song"}
                                    >
                                        <Gtk.Image iconName="media-playlist-shuffle-symbolic" />
                                    </Gtk.Button>
                                </Gtk.Box>
                            </Gtk.Button>
                        )) as any}
                    </For>
                </Gtk.Box>
            </Gtk.ScrolledWindow>
        </Gtk.Box>
    )
}