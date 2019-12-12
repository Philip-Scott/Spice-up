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
    private Gtk.Button replace_image;
    private Gtk.Button unlink_image;

    private unowned SlideManager manager;

    public ImageToolbar (SlideManager slide_manager) {
        this.manager = slide_manager;
    }

    construct {
        open_with = new Gtk.MenuButton ();
        open_with.add (new Gtk.Image.from_icon_name ("applications-graphics-symbolic", Gtk.IconSize.MENU));
        open_with.set_tooltip_text (_("Edit image with…"));
        open_with.get_style_context ().add_class ("spice");
        open_with.get_style_context ().add_class ("image-button");

        replace_image = new Gtk.Button ();
        replace_image.add (new Gtk.Image.from_icon_name ("document-new-symbolic", Gtk.IconSize.MENU));
        replace_image.set_tooltip_text (_("Replace Image…"));
        replace_image.get_style_context ().add_class ("spice");
        replace_image.get_style_context ().add_class ("image-button");

        // FIXME: Add unlink button
        unlink_image = new Gtk.Button ();
        unlink_image.add (new Gtk.Image.from_icon_name ("text-html-symbolic", Gtk.IconSize.MENU));
        unlink_image.set_tooltip_markup (_("Unlink shared file"));
        unlink_image.get_style_context ().add_class ("spice");
        unlink_image.get_style_context ().add_class ("image-button");

        unlink_image.clicked.connect (() => {
            var item = item as Spice.ImageItem;

            if (item != null) {
                item.image.copy_to_another_file ();
                unlink_image.sensitive = false;
            }
        });

        replace_image.clicked.connect (() => {
            var file = Spice.Services.FileManager.open_image ();

            if (file != null) {
                var image_item = (ImageItem) item;
                image_item.image.replace (file);
            }
        });

        add (open_with);
        add (replace_image);
        add (unlink_image);
    }

    private void launch_editor (AppInfo app) {
        var list = new List<File>();
        list.append (File.new_for_path (((ImageItem) this.item).url));

        try {
            app.launch (list, null);
        } catch (Error e) {
            warning ("Could launch application: %s", e.message);
        }
    }

    protected override void item_selected (Spice.CanvasItem? _item, bool new_item = false) {
        var item = _item as Spice.ImageItem;

        if (item != null) {
            var menu = new Gtk.Menu ();
            open_with.popup = menu;

            var file = File.new_for_path (item.url);

            try {
                var file_info = file.query_info ("standard::*", 0);

                var apps = AppInfo.get_all_for_type (file_info.get_content_type ());

                foreach (var app in apps) {
                    var meun_item = new Gtk.MenuItem.with_label (app.get_name ());
                    menu.add (meun_item);

                    meun_item.activate.connect (() => {
                        launch_editor (app);
                    });
                }

                menu.show_all ();
            } catch (Error e) {
                warning ("Could not get file info %s", e.message);
                return;
            }

            unlink_image.sensitive = manager.window.current_file.file_collector.file_references (item.image.current_image_file) > 1;
        }
    }

    public override void update_properties () {}
}
