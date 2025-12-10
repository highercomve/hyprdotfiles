import GObject, { register, property } from "ags/gobject"

@register({ GTypeName: "ControlPanelNav" })
export class ControlPanelNav extends GObject.Object {
	@property(String)
	page: string = "main"
}

const nav = new ControlPanelNav()
export default nav
