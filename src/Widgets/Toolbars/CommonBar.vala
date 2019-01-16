/*
* Copyright (c) 2016 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
* Authored by: Felipe Escoto <felescoto95@hotmail.com>
*/

public class Spice.Widgets.CommonToolbar : Spice.Widgets.Toolbar {
    public SlideManager manager { get; construct; }
    private Gtk.Button to_top;
    private Gtk.Button to_bottom;
    private Gtk.Button delete_button;
    private Gtk.Button clone_button;

    public CommonToolbar (SlideManager slide_manager) {
        Object (manager: slide_manager);
    }

    construct {
        hexpand = true;
        halign = Gtk.Align.END;

        delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.MENU);
        delete_button.set_tooltip_markup (Utils.get_accel_tooltip (Window.ACTION_DELETE, _("Delete")));
        delete_button.get_style_context ().add_class ("spice");

        delete_button.clicked.connect (manager.window.delete_object);

        clone_button = new Gtk.Button.from_icon_name ("edit-copy-symbolic", Gtk.IconSize.MENU);
        clone_button.get_style_context ().add_class ("spice");
        clone_button.set_tooltip_markup (Utils.get_accel_tooltip (Window.ACTION_CLONE, _("Clone")));

        clone_button.clicked.connect (() => {
            if (this.item != null) {
                Clipboard.duplicate (this.manager, this.item);
            } else {
                Clipboard.duplicate (this.manager, this.manager.current_slide);
            }
        });

        to_top = new Gtk.Button.from_icon_name ("selection-raise-symbolic", Gtk.IconSize.MENU);
        to_top.get_style_context ().add_class ("spice");
        to_top.set_tooltip_markup (Utils.get_accel_tooltip (Window.ACTION_BRING_FWD, _("Bring forward")));

        to_bottom = new Gtk.Button.from_icon_name ("selection-lower-symbolic", Gtk.IconSize.MENU);
        to_bottom.get_style_context ().add_class ("spice");
        to_bottom.set_tooltip_markup (Utils.get_accel_tooltip (Window.ACTION_BRING_BWD, _("Send backward")));

        var position_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        position_grid.get_style_context ().add_class ("linked");
        position_grid.add (to_top);
        position_grid.add (to_bottom);

        to_top.clicked.connect (this.manager.window.action_bring_fwd);
        to_bottom.clicked.connect (this.manager.window.action_send_bwd);

        add (position_grid);
        add (clone_button);
        add (delete_button);
    }

    protected override void item_selected (Spice.CanvasItem? item, bool new_item = false) {

    }

    public override void update_properties () {

    }
}
