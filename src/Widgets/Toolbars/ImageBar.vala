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

public class Spice.Widgets.ImageToolbar : Spice.Widgets.Toolbar {
    private Gtk.MenuButton open_with;

    construct {
        open_with = new Gtk.MenuButton ();
        open_with.add (new Gtk.Image.from_icon_name ("applications-graphics-symbolic", Gtk.IconSize.MENU));
        open_with.set_tooltip_text (_("Edit image with…"));
        open_with.get_style_context ().add_class ("spice");
        open_with.get_style_context ().add_class ("image-button");

        add (open_with);

        var menu = new Gtk.Menu ();
        open_with.popup = menu;

        var apps = AppInfo.get_all_for_type ("image/png");
        foreach (var app in apps) {
            var meun_item = new Gtk.MenuItem.with_label (app.get_name ());
            menu.add (meun_item);

            meun_item.activate.connect (() => {
                launch_editor (app);
            });
        }

        menu.show_all ();
    }

    private void launch_editor (AppInfo app) {
        var list = new List<File>();
        list.append (File.new_for_path (((ImageItem) this.item).url));

        app.launch (list, null);
    }

    protected override void item_selected (Spice.CanvasItem? _item, bool new_item = false) {}

    public override void update_properties () {}
}
