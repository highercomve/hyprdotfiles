import { Astal, Gtk, Gdk } from "ags/gtk4"
import { getScope } from "ags"
import GObject from "gi://GObject"

export type PopupWindowProps = Partial<Astal.Window.ConstructorProps> & {
	children?: any
	class?: string
	css?: string
	marginLeft?: number
	marginTop?: number
	marginRight?: number
	marginBottom?: number
	startMargin?: number
	endMargin?: number
	topMargin?: number
	bottomMargin?: number
	halign?: Gtk.Align
	valign?: Gtk.Align
	widthRequest?: number
	heightRequest?: number
	visible?: boolean
	actionClosed?: (self: Astal.Window) => void
	actionClickedOutside?: (self: Astal.Window) => void
	actionKeyPressed?: (
		self: Astal.Window,
		keyval: number,
		keycode: number,
	) => void
	$?: (self: Astal.Window) => void
}

export default function PopupWindow(props: PopupWindowProps) {
	const {
		actionClickedOutside = (self: Astal.Window) => self.hide(),
		actionKeyPressed,
		actionClosed,
		children,
		className,
		marginLeft,
		marginTop,
		marginRight,
		marginBottom,
		startMargin,
		endMargin,
		topMargin,
		bottomMargin,
		halign,
		valign,
		widthRequest,
		heightRequest,
		namespace = "popup-window",
		name = "popup-window",
		...windowProps
	} = props as PopupWindowProps

	let clickedInside = false

	return (
		<window
			name={name}
			namespace={namespace}
			{...windowProps}
			layer={windowProps.layer ?? Astal.Layer.OVERLAY}
			anchor={
				Astal.WindowAnchor.TOP |
				Astal.WindowAnchor.BOTTOM |
				Astal.WindowAnchor.LEFT |
				Astal.WindowAnchor.RIGHT
			}
			keymode={Astal.Keymode.EXCLUSIVE}
			exclusivity={Astal.Exclusivity.IGNORE}
			application={windowProps.application}
			css={`
				background-color: transparent;
			`}
			$={(self: Astal.Window) => {
				const gestureClick = Gtk.GestureClick.new()
				const keyController = Gtk.EventControllerKey.new()

				self.add_controller(gestureClick)
				self.add_controller(keyController)

				if (props.visible) self.show()

				gestureClick.connect("released", () => {
					if (clickedInside) {
						clickedInside = false
						return
					}
					actionClickedOutside(self)
				})

				keyController.connect("key-pressed", (_, keyval, keycode) => {
					if (keyval === Gdk.KEY_Escape) {
						actionClickedOutside(self)
						return true
					}
					actionKeyPressed?.(self, keyval, keycode)
				})
			}}
		>
			<box
				halign={halign ?? Gtk.Align.CENTER}
				valign={valign ?? Gtk.Align.CENTER}
				widthRequest={widthRequest}
				heightRequest={heightRequest}
				hexpand={false}
				vexpand={false}
				// We construct the CSS manually. Note that margin-start/end are Gtk4 standard.
				// We fallback to margin-left/right if start/end not provided, assuming LTR or specific intent.
				// If implicit margins specific to side are wanted, they are added.
				css={`
					${marginLeft !== undefined ? `margin-left: ${marginLeft}px;` : ""}
					${marginTop !== undefined ? `margin-top: ${marginTop}px;` : ""}
                 ${marginRight !== undefined
						? `margin-right: ${marginRight}px;`
						: ""}
                 ${marginBottom !== undefined
						? `margin-bottom: ${marginBottom}px;`
						: ""}
                 ${startMargin !== undefined
						? `margin-start: ${startMargin}px;`
						: ""}
                 ${endMargin !== undefined ? `margin-end: ${endMargin}px;` : ""}
                 ${topMargin !== undefined ? `margin-top: ${topMargin}px;` : ""}
                 ${bottomMargin !== undefined
						? `margin-bottom: ${bottomMargin}px;`
						: ""}
                 ${props.css ?? ""}
				`}
				$={(self: Gtk.Box) => {
					const gestureClick = Gtk.GestureClick.new()
					gestureClick.set_button(0)
					gestureClick.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
					self.add_controller(gestureClick)
					gestureClick.connect("pressed", () => {
						clickedInside = true
					})
					gestureClick.connect("released", () => {
						clickedInside = true
					})
				}}
			>
				{children}
			</box>
		</window>
	)
}
