import { createBinding, For, Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import App from "ags/gtk4/app"
import Mpris from "gi://AstalMpris"
import Pango from "gi://Pango"
import GLib from "gi://GLib"
import YouTubeService from "./YouTubeService"

// Helper to format time
function formatTime(seconds: number) {
	if (!seconds || seconds < 0) return "0:00"
	const min = Math.floor(seconds / 60)
	const sec = Math.floor(seconds % 60)
	return `${min}:${sec < 10 ? "0" + sec : sec}`
}

function MediaTicker({ player }: { player: Mpris.Player }) {
	const label = new Gtk.Label({
		maxWidthChars: 40,
		ellipsize: Pango.EllipsizeMode.NONE,
		halign: Gtk.Align.START,
	})

	let tick = 0
	const maxLen = 25 

	const update = () => {
		try {
			if (!player) return false
			const title = player.title || "Unknown"
			const artist = player.artist
			const content = artist ? `${title} - ${artist}` : title
			const pos = player.position >= 0 ? player.position : 0
			const len = player.length > 0 ? player.length : 0
			const timeStr = `(${formatTime(pos)}/${formatTime(len)})`

			let displayContent = content
			if (content.length > maxLen) {
				const padded = content + "   "
				const start = tick % padded.length
				let slice = padded.slice(start, start + maxLen)
				if (slice.length < maxLen) slice += padded.slice(0, maxLen - slice.length)
				displayContent = slice
				if (player.playbackStatus === Mpris.PlaybackStatus.PLAYING) tick++
			} else {
				tick = 0
			}
			label.label = `${displayContent} ${timeStr}`
		} catch (e) {}
		return true
	}

	const id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, update)
	setTimeout(update, 0)
	label.connect("destroy", () => GLib.source_remove(id))
	return label
}

// Memoized filter to avoid creating new closures on every binding evaluation
const filterActiveMprisPlayer = (ps: Mpris.Player[]) => {
    const filtered = ps.filter(p => !p.busName.includes("YouTubeMusic"))
    const active = filtered.find(p => p.playbackStatus === Mpris.PlaybackStatus.PLAYING) || filtered[0]
    return active ? [active] : []
}

export function MediaBar() {
	const mpris = Mpris.get_default()
	const players = createBinding(mpris, "players")
    const isYouTubePlaying = createBinding(YouTubeService, "isPlaying")

	return (
		<Gtk.Box class="media-bar">
            <Gtk.Stack
                transitionType={Gtk.StackTransitionType.CROSSFADE}
                $={(self) => {
                    // Guard against duplicate children on re-render
                    if (self.get_child_by_name("youtube")) return

                    const ytBox = (
                        <Gtk.Box class="media-bar-container" spacing={4}>
                            <Gtk.Button onClicked={() => App.toggle_window("center-popup")} class="media-bar-title" css="background: transparent; border: none;">
                                <Gtk.Box spacing={8}>
                                    <Gtk.Image iconName="emblem-music-symbolic" />
                                    <Gtk.Label label={createBinding(YouTubeService, "currentTitle").as(t => t || "YouTube Music")} />
                                </Gtk.Box>
                            </Gtk.Button>
                            <Gtk.Button onClicked={() => YouTubeService.pause()} class="media-bar-control" css="background: transparent; border: none;">
                                <Gtk.Image iconName="media-playback-pause-symbolic" />
                            </Gtk.Button>
                            <Gtk.Button onClicked={() => {}} class="media-bar-control" css="background: transparent; border: none;">
                                <Gtk.Image iconName="media-skip-forward-symbolic" />
                            </Gtk.Button>
                        </Gtk.Box>
                    )

                    const mprisBox = (
                        <Gtk.Box>
                            <For each={players.as(filterActiveMprisPlayer)}>
                                {(player) => (
                                    <Gtk.Box class="media-bar-container" spacing={4}>
                                        <Gtk.Button onClicked={() => App.toggle_window("center-popup")} class="media-bar-title" css="background: transparent; border: none;">
                                            <Gtk.Box spacing={8}>
                                                <Gtk.Image iconName="audio-x-generic-symbolic" />
                                                <MediaTicker player={player} />
                                            </Gtk.Box>
                                        </Gtk.Button>
                                        <Gtk.Button onClicked={() => player.play_pause()} class="media-bar-control" css="background: transparent; border: none;">
                                            <Gtk.Image iconName={createBinding(player, "playbackStatus").as(s => s === Mpris.PlaybackStatus.PLAYING ? "media-playback-pause-symbolic" : "media-playback-start-symbolic")} />
                                        </Gtk.Button>
                                        <Gtk.Button onClicked={() => player.next()} class="media-bar-control" css="background: transparent; border: none;">
                                            <Gtk.Image iconName="media-skip-forward-symbolic" />
                                        </Gtk.Button>
                                    </Gtk.Box>
                                )}
                            </For>
                        </Gtk.Box>
                    )

                    const emptyBox = (
                        <Gtk.Box class="media-bar-container" spacing={4} halign={Gtk.Align.CENTER}>
                            <Gtk.Button onClicked={() => App.toggle_window("center-popup")} class="media-bar-title" css="background: transparent; border: none;">
                                <Gtk.Box spacing={8}>
                                    <Gtk.Image iconName="audio-x-generic-symbolic" />
                                    <Gtk.Label label="No Media" />
                                </Gtk.Box>
                            </Gtk.Button>
                        </Gtk.Box>
                    )

                    self.add_named(ytBox, "youtube")
                    self.add_named(mprisBox, "mpris")
                    self.add_named(emptyBox, "empty")

                    const update = () => {
                        if (YouTubeService.isPlaying) {
                            self.set_visible_child_name("youtube")
                        } else {
                            const otherPlayers = mpris.players.filter(p => !p.busName.includes("YouTubeMusic"))
                            if (otherPlayers.length > 0) {
                                self.set_visible_child_name("mpris")
                            } else {
                                self.set_visible_child_name("empty")
                            }
                        }
                    }

                    const id1 = YouTubeService.connect("notify::is-playing", update)
                    const id2 = mpris.connect("notify::players", update)
                    update()
                    
                    self.connect("destroy", () => {
                        YouTubeService.disconnect(id1)
                        mpris.disconnect(id2)
                    })
                }}
            />
		</Gtk.Box>
	)
}

function CoverArt({ cover }: { cover: Accessor<string> }) {
	return (
		<Gtk.Box class="cover-art-container" halign={Gtk.Align.CENTER}>
			<Gtk.Image visible={cover.as(c => c === "")} iconName="audio-x-generic-symbolic" pixelSize={200} css="border-radius: 12px; opacity: 0.5;" />
			<Gtk.Image visible={cover.as(c => c !== "")} file={cover} pixelSize={200} />
		</Gtk.Box>
	)
}

function YouTubePlayerWidget() {
    const title = createBinding(YouTubeService, "currentTitle")
    const artist = createBinding(YouTubeService, "currentArtist")
    const isPlaying = createBinding(YouTubeService, "isPlaying")
    const position = createBinding(YouTubeService, "position")
    const duration = createBinding(YouTubeService, "duration")
    const adjustment = new Gtk.Adjustment({ lower: 0, upper: 100, value: 0 })

    return (
        <Gtk.Box class="media-player-window" orientation={Gtk.Orientation.VERTICAL} spacing={16} hexpand>
            <Gtk.Box class="cover-art-container" halign={Gtk.Align.CENTER} css="margin-bottom: 10px;">
                <Gtk.Image iconName="emblem-music-symbolic" pixelSize={200} css="border-radius: 12px; opacity: 0.5;" />
            </Gtk.Box>
            <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={4} halign={Gtk.Align.CENTER}>
                <Gtk.Label class="title" label={title.as(t => t || "YouTube Music")} css="font-size: 1.3em; font-weight: bold;" />
                <Gtk.Label class="artist" label={artist.as(a => a || "Search for a song")} css="color: #a6adc8; font-size: 1.1em;" />
            </Gtk.Box>
            <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={4} hexpand>
                <Gtk.Scale hexpand adjustment={adjustment} onChangeValue={(self, _, value) => YouTubeService.set_position(value)} $={(self) => {
                    const id = YouTubeService.connect("notify::position", () => self.adjustment.value = YouTubeService.position)
                    const id2 = YouTubeService.connect("notify::duration", () => self.adjustment.upper = YouTubeService.duration || 100)
                    self.connect("destroy", () => { YouTubeService.disconnect(id); YouTubeService.disconnect(id2) })
                }}/>
                <Gtk.Box hexpand halign={Gtk.Align.FILL}>
                    <Gtk.Label halign={Gtk.Align.START} label={position.as(formatTime)} css="color: #a6adc8; font-size: 0.9em;" />
                    <Gtk.Box hexpand />
                    <Gtk.Label halign={Gtk.Align.END} label={duration.as(formatTime)} css="color: #a6adc8; font-size: 0.9em;" />
                </Gtk.Box>
            </Gtk.Box>
            <Gtk.Box class="controls" spacing={32} halign={Gtk.Align.CENTER}>
                <Gtk.Button class="control-button"><Gtk.Image iconName="media-skip-backward-symbolic" pixelSize={24} /></Gtk.Button>
                <Gtk.Button onClicked={() => YouTubeService.isPlaying ? YouTubeService.pause() : YouTubeService.resume()} class="play-button">
                    <Gtk.Image iconName={isPlaying.as(p => p ? "media-playback-pause-symbolic" : "media-playback-start-symbolic")} pixelSize={32} />
                </Gtk.Button>
                <Gtk.Button class="control-button"><Gtk.Image iconName="media-skip-forward-symbolic" pixelSize={24} /></Gtk.Button>
            </Gtk.Box>
        </Gtk.Box>
    )
}

export default function Media() {
	const mpris = Mpris.get_default()
	const players = createBinding(mpris, "players")
	return (
		<Gtk.Box class="media-widget" hexpand>
            <Gtk.Stack transitionType={Gtk.StackTransitionType.SLIDE_LEFT_RIGHT} $={(self) => {
                // Guard against duplicate children on re-render
                if (self.get_child_by_name("mpris")) return

                const mprisBox = (
                    <Gtk.Box orientation={Gtk.Orientation.VERTICAL}>
                        <For each={players.as(filterActiveMprisPlayer)}>
                            {(player: Mpris.Player) => <HookWidget player={player} />}
                        </For>
                        <Gtk.Box visible={players.as(ps => ps.filter(p => !p.busName.includes("YouTubeMusic")).length === 0)} class="media-player-window" orientation={Gtk.Orientation.VERTICAL} spacing={16} hexpand valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER}>
                            <Gtk.Image iconName="audio-x-generic-symbolic" pixelSize={96} css="opacity: 0.5;" />
                            <Gtk.Label label="No Media Playing" css="font-size: 1.2em; opacity: 0.7;" />
                        </Gtk.Box>
                    </Gtk.Box>
                )
                self.add_named(mprisBox, "mpris")
                self.add_named(<YouTubePlayerWidget />, "youtube")
                const update = () => self.set_visible_child_name(YouTubeService.isPlaying ? "youtube" : "mpris")
                const id = YouTubeService.connect("notify::is-playing", update)
                update()
                self.connect("destroy", () => YouTubeService.disconnect(id))
            }} />
		</Gtk.Box>
	)
}

function HookWidget({ player }: { player: Mpris.Player }) {
	const title = createBinding(player, "title")
	const artist = createBinding(player, "artist")
	const album = createBinding(player, "album")
	const status = createBinding(player, "playbackStatus")
	const cover = createBinding(player, "coverArt")
	const adjustment = new Gtk.Adjustment({ lower: 0, upper: player.length || 100, value: player.position || 0 })
	const id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
		if (player.playbackStatus === Mpris.PlaybackStatus.PLAYING) {
			if (typeof player.position === "number" && !isNaN(player.position)) adjustment.value = player.position
		}
		if (typeof player.length === "number" && player.length > 0) adjustment.upper = player.length
		return true
	})
	const widget = (
		<Gtk.Box class="media-player-window" orientation={Gtk.Orientation.VERTICAL} spacing={16} hexpand>
			<Gtk.Box class="cover-art-container" halign={Gtk.Align.CENTER} css="margin-bottom: 10px;"><CoverArt cover={cover} /></Gtk.Box>
			<Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={4} halign={Gtk.Align.CENTER}>
				<Gtk.Label class="title" label={title.as(t => t || "Unknown Title")} wrap justify={Gtk.Justification.CENTER} maxWidthChars={30} ellipsize={Pango.EllipsizeMode.END} css="font-size: 1.3em; font-weight: bold;" />
				<Gtk.Label class="artist" label={artist.as(a => a || "Unknown Artist")} wrap justify={Gtk.Justification.CENTER} maxWidthChars={30} ellipsize={Pango.EllipsizeMode.END} css="color: #a6adc8; font-size: 1.1em;" />
				<Gtk.Label class="album" label={album.as(a => a || "")} wrap justify={Gtk.Justification.CENTER} maxWidthChars={30} ellipsize={Pango.EllipsizeMode.END} css="color: #6c7086; font-size: 0.9em;" />
			</Gtk.Box>
			<Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={4} hexpand>
				<Gtk.Scale hexpand adjustment={adjustment} onChangeValue={(self, scroll, value) => { if (typeof value === "number" && !isNaN(value)) player.position = value }} />
				<Gtk.Box hexpand halign={Gtk.Align.FILL}>
					<Gtk.Label halign={Gtk.Align.START} label={createBinding(adjustment, "value").as(formatTime)} css="color: #a6adc8; font-size: 0.9em;" />
					<Gtk.Box hexpand />
					<Gtk.Label halign={Gtk.Align.END} label={createBinding(adjustment, "upper").as(formatTime)} css="color: #a6adc8; font-size: 0.9em;" />
				</Gtk.Box>
			</Gtk.Box>
			<Gtk.Box class="controls" spacing={32} halign={Gtk.Align.CENTER} css="margin-top: 10px;">
				<Gtk.Button onClicked={() => player.previous()} class="control-button" valign={Gtk.Align.CENTER}><Gtk.Image iconName="media-skip-backward-symbolic" pixelSize={24} /></Gtk.Button>
				<Gtk.Button onClicked={() => player.play_pause()} class="play-button" valign={Gtk.Align.CENTER}><Gtk.Image iconName={status.as(s => s === Mpris.PlaybackStatus.PLAYING ? "media-playback-pause-symbolic" : "media-playback-start-symbolic")} pixelSize={32} /></Gtk.Button>
				<Gtk.Button onClicked={() => player.next()} class="control-button" valign={Gtk.Align.CENTER}><Gtk.Image iconName="media-skip-forward-symbolic" pixelSize={24} /></Gtk.Button>
			</Gtk.Box>
		</Gtk.Box>
	)
	widget.connect("destroy", () => GLib.source_remove(id))
	return widget
}