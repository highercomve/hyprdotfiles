import { createBinding, For, Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import App from "ags/gtk4/app"
import Mpris from "gi://AstalMpris"
import Pango from "gi://Pango"
import GLib from "gi://GLib"

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
	const maxLen = 25 // Characters for title/artist to show

	const update = () => {
		try {
			if (!player) return false

			const title = player.title || "Unknown"
			const artist = player.artist
			const content = artist ? `${title} - ${artist}` : title

			const pos = player.position >= 0 ? player.position : 0
			const len = player.length > 0 ? player.length : 0
			const timeStr = `(${formatTime(pos)}/${formatTime(len)})`

			// Scrolling logic
			let displayContent = content
			if (content.length > maxLen) {
				const padded = content + "   "
				const start = tick % padded.length
				let slice = padded.slice(start, start + maxLen)
				// Wrap around if slice is shorter than window
				if (slice.length < maxLen) {
					slice += padded.slice(0, maxLen - slice.length)
				}
				displayContent = slice

				if (player.playbackStatus === Mpris.PlaybackStatus.PLAYING) {
					tick++
				}
			} else {
				tick = 0
			}

			label.label = `${displayContent} ${timeStr}`
		} catch (e) {
			console.error(e)
		}
		return true
	}

	const id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, update)
	// Initial update
	setTimeout(update, 0)

	label.connect("destroy", () => GLib.source_remove(id))

	return label
}

// Bar Component: Quick Controls + Title
export function MediaBar() {
	const mpris = Mpris.get_default()
	const players = createBinding(mpris, "players")

	const activePlayerList = players.as((ps) => {
		const active =
			ps.find((p) => p.playbackStatus === Mpris.PlaybackStatus.PLAYING) || ps[0]
		return active ? [active] : []
	})

	const hasMedia = activePlayerList.as((l) => l.length > 0)

	return (
		<box class="media-bar">
			{/* Active Player */}
			<For each={activePlayerList}>
				{(player) => {
					const status = createBinding(player, "playbackStatus")

					return (
						<box class="media-bar-container" spacing={4}>
							{/* Main Pill: Icon + Title */}
							<button
								onClicked={() => App.toggle_window("center-popup")}
								class="media-bar-title"
							>
								<box spacing={8}>
									<Gtk.Image iconName="audio-x-generic-symbolic" />
									<MediaTicker player={player} />
								</box>
							</button>

							{/* Quick Controls */}
							<button
								onClicked={() => player.play_pause()}
								class="media-bar-control"
							>
								<Gtk.Image
									iconName={status.as((s) =>
										s === Mpris.PlaybackStatus.PLAYING
											? "media-playback-pause-symbolic"
											: "media-playback-start-symbolic",
									)}
								/>
							</button>
							<button onClicked={() => player.next()} class="media-bar-control">
								<Gtk.Image iconName="media-skip-forward-symbolic" />
							</button>
						</box>
					)
				}}
			</For>

			{/* No Media Placeholder */}
			<box
				visible={hasMedia.as((v) => !v)}
				class="media-bar-container"
				spacing={4}
			>
				<button
					onClicked={() => App.toggle_window("center-popup")}
					class="media-bar-title"
				>
					<box spacing={8}>
						<Gtk.Image iconName="audio-x-generic-symbolic" />
						<Gtk.Label
							label="No Media"
							maxWidthChars={20}
							ellipsize={Pango.EllipsizeMode.END}
						/>
					</box>
				</button>
			</box>
		</box>
	)
}

function CoverArt({ cover }: { cover: Accessor<string> }) {
	return (
		<box class="cover-art-container" halign={Gtk.Align.CENTER}>
			<Gtk.Image
				visible={cover.as((c) => c === "")}
				iconName="audio-x-generic-symbolic"
				pixelSize={200}
				css="border-radius: 12px; opacity: 0.5;"
			/>
			<Gtk.Image
				visible={cover.as((c) => c !== "")}
				file={cover}
				pixelSize={200}
			/>
		</box>
	)
}

// Control Panel Component: Rich Player
export default function Media() {
	const mpris = Mpris.get_default()
	const players = createBinding(mpris, "players")

	const activePlayerList = players.as((ps) => {
		const active =
			ps.find((p) => p.playbackStatus === Mpris.PlaybackStatus.PLAYING) || ps[0]
		return active ? [active] : []
	})

	const hasMedia = activePlayerList.as((l) => l.length > 0)

	return (
		<box class="media-widget" hexpand>
			<For each={activePlayerList}>
				{(player: Mpris.Player) => {
					return <HookWidget player={player} />
				}}
			</For>

			<box
				visible={hasMedia.as((v) => !v)}
				class="media-player-window"
				orientation={Gtk.Orientation.VERTICAL}
				spacing={16}
				hexpand
				valign={Gtk.Align.CENTER}
				halign={Gtk.Align.CENTER}
			>
				<Gtk.Image
					iconName="audio-x-generic-symbolic"
					pixelSize={96}
					css="opacity: 0.5;"
				/>
				<Gtk.Label
					label="No Media Playing"
					css="font-size: 1.2em; opacity: 0.7;"
				/>
			</box>
		</box>
	)
}

// Separate component to handle lifecycle easily
function HookWidget({ player }: { player: Mpris.Player }) {
	const title = createBinding(player, "title")
	const artist = createBinding(player, "artist")
	const album = createBinding(player, "album")
	const status = createBinding(player, "playbackStatus")
	const cover = createBinding(player, "coverArt")

	const adjustment = new Gtk.Adjustment({
		lower: 0,
		upper: player.length || 100,
		value: player.position || 0,
	})

	const id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
		if (player.playbackStatus === Mpris.PlaybackStatus.PLAYING) {
			if (typeof player.position === "number" && !isNaN(player.position)) {
				adjustment.value = player.position
			}
		}
		if (typeof player.length === "number" && player.length > 0) {
			adjustment.upper = player.length
		}
		return true
	})

	const widget = (
		<box
			class="media-player-window"
			orientation={Gtk.Orientation.VERTICAL}
			spacing={16}
			hexpand
		>
			<box
				class="cover-art-container"
				halign={Gtk.Align.CENTER}
				css="margin-bottom: 10px;"
			>
				<CoverArt cover={cover} />
			</box>

			{/* Info */}
			<box
				orientation={Gtk.Orientation.VERTICAL}
				spacing={4}
				halign={Gtk.Align.CENTER}
			>
				<Gtk.Label
					class="title"
					label={title.as((t) => t || "Unknown Title")}
					wrap
					justify={Gtk.Justification.CENTER}
					maxWidthChars={30}
					ellipsize={Pango.EllipsizeMode.END}
					css="font-size: 1.3em; font-weight: bold;"
				/>
				<Gtk.Label
					class="artist"
					label={artist.as((a) => a || "Unknown Artist")}
					wrap
					justify={Gtk.Justification.CENTER}
					maxWidthChars={30}
					ellipsize={Pango.EllipsizeMode.END}
					css="color: #a6adc8; font-size: 1.1em;"
				/>
				<Gtk.Label
					class="album"
					label={album.as((a) => a || "")}
					wrap
					justify={Gtk.Justification.CENTER}
					maxWidthChars={30}
					ellipsize={Pango.EllipsizeMode.END}
					css="color: #6c7086; font-size: 0.9em;"
				/>
			</box>

			{/* Progress Bar & Time */}
			<box orientation={Gtk.Orientation.VERTICAL} spacing={4} hexpand>
				<Gtk.Scale
					hexpand
					adjustment={adjustment}
					onChangeValue={(self, scroll, value) => {
						// The signal signature for "change-value" is (GtkRange *range, GtkScrollType scroll, gdouble value, gpointer user_data)
						// But in GJS/TS types it might map slightly differently, usually (self, scroll, value).
						// The error logs showed 'nan' for property 'position'.
						// If we get here, 'value' is strictly the new value to set.

						if (typeof value === "number" && !isNaN(value)) {
							player.position = value
						}
					}}
				/>
				<box hexpand halign={Gtk.Align.FILL}>
					<Gtk.Label
						halign={Gtk.Align.START}
						label={createBinding(adjustment, "value").as(formatTime)}
						css="color: #a6adc8; font-size: 0.9em;"
					/>
					<box hexpand />
					<Gtk.Label
						halign={Gtk.Align.END}
						label={createBinding(adjustment, "upper").as(formatTime)}
						css="color: #a6adc8; font-size: 0.9em;"
					/>
				</box>
			</box>

			{/* Controls */}
			<box
				class="controls"
				spacing={32}
				halign={Gtk.Align.CENTER}
				css="margin-top: 10px;"
			>
				<button onClicked={() => player.previous()} class="control-button" valign={Gtk.Align.CENTER}>
					<Gtk.Image iconName="media-skip-backward-symbolic" pixelSize={24} />
				</button>
				<button
					onClicked={() => player.play_pause()}
					class="play-button"
					valign={Gtk.Align.CENTER}
				>
					<Gtk.Image
						iconName={status.as((s) =>
							s === Mpris.PlaybackStatus.PLAYING
								? "media-playback-pause-symbolic"
								: "media-playback-start-symbolic",
						)}
						pixelSize={32}
					/>
				</button>
				<button onClicked={() => player.next()} class="control-button" valign={Gtk.Align.CENTER}>
					<Gtk.Image iconName="media-skip-forward-symbolic" pixelSize={24} />
				</button>
			</box>
		</box>
	)

	widget.connect("destroy", () => {
		GLib.source_remove(id)
	})

	return widget
}
