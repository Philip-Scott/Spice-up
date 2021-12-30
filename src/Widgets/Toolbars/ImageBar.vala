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
    private Gtk.Button open_with;
    private Gtk.Button replace_image;

    private unowned SlideManager manager;

    public ImageToolbar (SlideManager slide_manager) {
        this.manager = slide_manager;
    }

    construct {
        open_with = new Gtk.Button ();
        open_with.add (new Gtk.Image.from_icon_name ("applications-graphics-symbolic", Gtk.IconSize.MENU));
        open_with.set_tooltip_text (_("Edit image with…"));
        open_with.get_style_context ().add_class (Gtk.STYLE_CLASS_RAISED);
        open_with.get_style_context ().add_class ("image-button");

        open_with.clicked.connect (() => {
            var image_item = (ImageItem) item;
            var file = File.new_for_path (image_item.url);

            try {
                Gtk.show_uri_on_window(Application.get_active_spice_window (), file.get_uri (), Gdk.CURRENT_TIME);
            } catch (Error e) {
                warning ("Could not launch open with portal %s", e.message);
                return;
            }
        });

        replace_image = new Gtk.Button ();
        replace_image.add (new Gtk.Image.from_icon_name ("document-new-symbolic", Gtk.IconSize.MENU));
        replace_image.set_tooltip_text (_("Replace Image…"));
        replace_image.get_style_context ().add_class (Gtk.STYLE_CLASS_RAISED);
        replace_image.get_style_context ().add_class ("image-button");

        replace_image.clicked.connect (() => {
            var file = Spice.Services.FileManager.open_image ();

            if (file != null) {
                var image_item = (ImageItem) item;
                image_item.image.replace (file);
            }
        });

        add (open_with);
        add (replace_image);
    }

    protected override void item_selected (Spice.CanvasItem? _item, bool new_item = false) {}

    public override void update_properties () {}
}
