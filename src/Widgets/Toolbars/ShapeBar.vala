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

public class Spice.Widgets.ShapeToolbar : Spice.Widgets.Toolbar {
    private Spice.ColorPicker background_color_button;
    private Gtk.Scale border_radius;

    construct {
        border_radius = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0.0, 50.0, 1);
        border_radius.add_mark (0.0, Gtk.PositionType.BOTTOM, _("Square"));
        border_radius.add_mark (50.0, Gtk.PositionType.BOTTOM, _("Circle"));
        border_radius.width_request = 200;
        border_radius.draw_value = false;
        border_radius.margin = 12;

        var border_radius_button = new Gtk.Button.from_icon_name ("applications-engineering-symbolic", Gtk.IconSize.MENU);
        border_radius_button.get_style_context ().add_class ("spice");
        border_radius_button.set_tooltip_text (_("Roundness"));

        var border_radius_popover = new Gtk.Popover (border_radius_button);
        border_radius_popover.position = Gtk.PositionType.BOTTOM;

        border_radius_popover.add (border_radius);

        border_radius_button.clicked.connect (() => {
            border_radius_popover.show ();
            border_radius_popover.show_all ();
        });

        border_radius.value_changed.connect (() => {
            var action = new Spice.Services.HistoryManager.HistoryAction<ColorItem,int>.item_changed (this.item as ColorItem, "border-radius");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_properties ();
        });

        background_color_button = new Spice.ColorPicker ();
        background_color_button.set_tooltip_text (_("Shape color"));
        background_color_button.gradient = true;

        background_color_button.color_picked.connect ((color) => {
            var action = new Spice.Services.HistoryManager.HistoryAction<ColorItem,string>.item_changed (this.item as ColorItem, "background-color");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_properties ();
        });

        add (background_color_button);
        add (border_radius_button);
    }

    protected override void item_selected (Spice.CanvasItem? _item, bool new_item = false) {
        if (new_item) {
            update_properties ();
            return;
        }
        var item = _item as ColorItem;

        background_color_button.color = item.background_color;
        border_radius.set_value (item.border_radius);
    }

    public override void update_properties () {
        ColorItem color = (ColorItem) item;
        color.background_color = background_color_button.color;

        color.border_radius = (int) border_radius.get_value ();

        item.style ();
    }
}
