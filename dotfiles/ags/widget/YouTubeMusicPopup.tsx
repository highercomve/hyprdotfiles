import { Astal, Gtk, Gdk } from "ags/gtk4"
import App from "ags/gtk4/app"
import { createBinding, For } from "ags"
import YouTubeService from "./YouTubeService"
import Pango from "gi://Pango"
import PopupWindow from "./PopupWindow"

function LoginView() {
    return (
        <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={12} halign={Gtk.Align.CENTER} css="padding: 20px;">
            <Gtk.Label label="YouTube Music Login" css="font-size: 1.2em; font-weight: bold; color: #cdd6f4;" />
            <Gtk.Label label="Login to access your playlists and liked songs." css="color: #a6adc8;" />
            
            <Gtk.Stack
                transitionType={Gtk.StackTransitionType.CROSSFADE}
                $={(self) => {
                    // Guard against duplicate children on re-render
                    if (self.get_child_by_name("button")) return

                    const btn = (
                        <Gtk.Button 
                            onClicked={() => YouTubeService.startLogin()}
                            css="background-color: #f38ba8; color: #1e1e2e; border-radius: 8px; padding: 8px 16px; font-weight: bold;"
                        >
                            <Gtk.Label label="Start Login Process" />
                        </Gtk.Button>
                    )
                    const code = (
                        <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                            <Gtk.Label label="Go to:" css="color: #a6adc8;" />
                            <Gtk.Label label={createBinding(YouTubeService, "loginUrl")} css="color: #89b4fa; text-decoration: underline;" />
                            <Gtk.Label label="And enter this code:" css="color: #a6adc8;" />
                            <Gtk.Label label={createBinding(YouTubeService, "loginCode")} css="font-size: 2em; font-weight: bold; color: #fab387; background: #313244; padding: 10px; border-radius: 8px;" />
                            <Gtk.Label label="Waiting for authentication..." css="font-style: italic; color: #6c7086;" />
                        </Gtk.Box>
                    )
                    self.add_named(btn, "button")
                    self.add_named(code, "code")

                    const apply = () => {
                        self.set_visible_child_name(YouTubeService.loginCode ? "code" : "button")
                    }
                    apply()
                    const id = YouTubeService.connect("notify::login-code", apply)
                    self.connect("destroy", () => YouTubeService.disconnect(id))
                }}
            />
        </Gtk.Box>
    )
}

function LibraryView() {
    return (
        <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
            <Gtk.Label label="Your Playlists" halign={Gtk.Align.START} css="font-weight: bold; color: #cdd6f4; margin-left: 8px;" />
            <Gtk.Label
                visible={createBinding(YouTubeService, "libraryError").as(e => e !== "")}
                label={createBinding(YouTubeService, "libraryError")}
                wrap
                halign={Gtk.Align.START}
                maxWidthChars={36}
                css="color: #f38ba8; font-size: 0.85em; margin-left: 8px;"
            />
            <Gtk.ScrolledWindow
                hscrollbarPolicy={Gtk.PolicyType.NEVER}
                vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                css="min-height: 150px; max-height: 200px;"
            >
                <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    <For each={createBinding(YouTubeService, "userPlaylists")}>
                        {((pl: any) => (
                            <Gtk.Button
                                onClicked={() => {
                                    console.log("Loading playlist:", pl.title)
                                }}
                                css="background-color: #181825; border: none; border-radius: 8px; padding: 8px; text-align: left;"
                            >
                                <Gtk.Box spacing={8}>
                                    <Gtk.Image iconName="folder-music-symbolic" />
                                    <Gtk.Label label={pl.title || "Untitled"} css="color: #cdd6f4;" />
                                </Gtk.Box>
                            </Gtk.Button>
                        )) as any}
                    </For>
                </Gtk.Box>
            </Gtk.ScrolledWindow>
        </Gtk.Box>
    )
}

function MainView() {
    return (
        <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={12}>
            {/* Search Bar */}
            <Gtk.Box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
                <Gtk.Image iconName="system-search-symbolic" />
                <Gtk.Entry
                    hexpand
                    placeholderText="Search YouTube Music..."
                    onActivate={(self) => {
                        if (self.text) {
                            YouTubeService.search(self.text)
                        }
                    }}
                    css="background-color: #313244; color: #cdd6f4; border: none; border-radius: 6px; padding: 4px 8px;"
                />
            </Gtk.Box>

            {/* Now Playing Status */}
            <Gtk.Box orientation={Gtk.Orientation.HORIZONTAL} spacing={8} visible={createBinding(YouTubeService, "currentTitle").as(t => t !== "")}>
                <Gtk.Image iconName="audio-x-generic-symbolic" />
                <Gtk.Label
                    label={createBinding(YouTubeService, "currentTitle")}
                    css="color: #a6e3a1; font-weight: bold;"
                    maxWidthChars={30}
                    ellipsize={Pango.EllipsizeMode.END}
                />
                <Gtk.Box hexpand />
                <Gtk.Button
                    onClicked={() => {
                        if (YouTubeService.isPlaying) YouTubeService.pause();
                        else YouTubeService.resume();
                    }}
                    css="background: transparent; border: none;"
                >
                    <Gtk.Image iconName={createBinding(YouTubeService, "isPlaying").as(p => p ? "media-playback-pause-symbolic" : "media-playback-start-symbolic")} />
                </Gtk.Button>
                <Gtk.Button onClicked={() => YouTubeService.stop()} css="background: transparent; border: none;">
                    <Gtk.Image iconName="media-playback-stop-symbolic" />
                </Gtk.Button>
            </Gtk.Box>

            <LibraryView />

            <Gtk.Box css="min-height: 1px; background-color: #313244;" />
            <Gtk.Label label="Search Results" halign={Gtk.Align.START} css="font-weight: bold; color: #cdd6f4; margin-left: 8px;" />

            {/* Results Area */}
            <Gtk.ScrolledWindow
                hscrollbarPolicy={Gtk.PolicyType.NEVER}
                vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                css="min-height: 200px; max-height: 300px;"
            >
                <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    <Gtk.Label
                        label="Searching..."
                        css="padding: 20px; color: #6c7086;"
                        visible={createBinding(YouTubeService, "isSearching")}
                    />
                    <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                        <For each={createBinding(YouTubeService, "searchResults")}>
                            {((res: any) => (
                                <Gtk.Button
                                    class="ytm-result-button"
                                    onClicked={() => {
                                        YouTubeService.play(res.videoId, res.name, res.artist?.name || "Unknown")
                                    }}
                                    css="background-color: #181825; border: none; border-radius: 8px; padding: 8px; text-align: left;"
                                >
                                    <Gtk.Box orientation={Gtk.Orientation.VERTICAL}>
                                        <Gtk.Label
                                            label={res.name || "Unknown"}
                                            halign={Gtk.Align.START}
                                            css="color: #cdd6f4; font-weight: bold;"
                                            maxWidthChars={40}
                                            ellipsize={Pango.EllipsizeMode.END}
                                        />
                                        <Gtk.Label
                                            label={res.artist?.name || ""}
                                            halign={Gtk.Align.START}
                                            css="color: #a6adc8; font-size: 0.9em;"
                                            maxWidthChars={40}
                                            ellipsize={Pango.EllipsizeMode.END}
                                        />
                                    </Gtk.Box>
                                </Gtk.Button>
                            )) as any}
                        </For>
                    </Gtk.Box>
                </Gtk.Box>
            </Gtk.ScrolledWindow>
        </Gtk.Box>
    )
}

export default function YouTubeMusicPopup() {
    return (
        <PopupWindow
            name="youtubemusic-popup"
            application={App}
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.START}
            marginTop={40}
            widthRequest={450}
            layer={Astal.Layer.OVERLAY}
            keymode={Astal.Keymode.ON_DEMAND}
        >
            <Gtk.Box class="ytm-popup" orientation={Gtk.Orientation.VERTICAL} spacing={12} css="background-color: #1e1e2e; border-radius: 12px; padding: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.5); border: 1px solid #313244;">
                <Gtk.Stack
                    transitionType={Gtk.StackTransitionType.SLIDE_LEFT_RIGHT}
                    $={(self) => {
                        // Guard against duplicate children on re-render
                        if (self.get_child_by_name("login")) return

                        self.add_named(<LoginView />, "login")
                        self.add_named(<MainView />, "main")
                        
                        const update = () => {
                            self.set_visible_child_name(YouTubeService.isLoggedIn ? "main" : "login")
                        }
                        
                        const id = YouTubeService.connect("notify::is-logged-in", update)
                        update() // Initial state
                        
                        self.connect("destroy", () => YouTubeService.disconnect(id))
                    }}
                />
            </Gtk.Box>
        </PopupWindow>
    )
}
