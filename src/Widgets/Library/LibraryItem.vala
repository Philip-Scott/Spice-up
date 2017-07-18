/*
* Copyright (c) 2017 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

public class Spice.Widgets.Library.LibraryItem : Gtk.FlowBoxChild {
    public File file { get; construct set; }

    private Gtk.Image image;
    private Gtk.Popover? popover = null;

    private string last_aspect_ratio;
    private string data;

    public LibraryItem (File file) {
        this.file = file;

        var event_box = new Gtk.EventBox ();
        event_box.events |= Gdk.EventMask.BUTTON_RELEASE_MASK;

        set_tooltip_text (_("Open: %s".printf (file.get_path ())));
        halign = Gtk.Align.CENTER;

        image = new Gtk.Image ();
        image.events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
        image.margin = 12;

        image.get_style_context ().add_class ("card");

        event_box.add (image);
        add (event_box);

        get_thumbnail ();
        show_all ();

        event_box.button_release_event.connect ((event) => {
            if (event.button != 3) return false;
            show_popover ();

            return true;
        });
    }

    private void show_popover () {
        if (popover == null) {
            var name_label = new Gtk.Label (_("Name: "));
            name_label.halign = Gtk.Align.END;

            var name_entry = new Gtk.Entry ();
            name_entry.text = file.get_basename ().replace (".spice", "");

            var ratio_label = new Gtk.Label (_("Aspect Ratio: "));
            ratio_label.halign = Gtk.Align.END;

            var aspect_ratio = new Gtk.ComboBoxText ();
            aspect_ratio.append ("1", _("4:3"));
            aspect_ratio.append ("2", _("16:9"));
            aspect_ratio.append ("3", _("16:10"));
            aspect_ratio.append ("4", _("3:2"));
            aspect_ratio.append ("5", _("5:4"));

            last_aspect_ratio = "%d".printf (Utils.get_aspect_ratio (data));
            aspect_ratio.set_active_id (last_aspect_ratio);

            var grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.column_spacing = 6;
            grid.margin = 6;

            grid.attach (name_label, 0, 0, 1, 1);
            grid.attach (name_entry, 1, 0, 1, 1);
            grid.attach (ratio_label, 0, 1, 1, 1);
            grid.attach (aspect_ratio, 1, 1, 1, 1);

            grid.show_all ();

            popover = new Gtk.Popover (image);
            popover.position = Gtk.PositionType.LEFT;
            popover.add (grid);

            popover.closed.connect (() => {
                var new_name = name_entry.get_text () + ".spice";
                if (new_name != this.file.get_basename ()) {
                    var path = this.file.get_parent ().get_path ();
                    var new_file = File.new_for_path ("%s/%s".printf (path, new_name));

                    if (new_file.query_exists ()) {
                        window.add_toast_notification (new Granite.Widgets.Toast (_("Could not rename: File already exists...")));
                        return;
                    }

                    FileUtils.rename (this.file.get_path (), new_file.get_path ());
                    Spice.Services.Settings.get_instance ().add_file (new_file.get_path ());

                    this.file = new_file;
                }

                if (aspect_ratio.get_active_id () != last_aspect_ratio) {
                    Spice.SlideManager.aspect_ratio_override = int.parse (aspect_ratio.get_active_id ());
                    activate ();
                }
            });
        }

        popover.show ();
    }

    private void get_thumbnail () {
        if (file.query_exists ()) {
            FileUtils.get_contents (file.get_path (), out data);

            var pixbuf = Utils.base64_to_pixbuf (Utils.get_thumbnail_data (data));
            image.set_from_pixbuf (pixbuf);
        }
    }
}
