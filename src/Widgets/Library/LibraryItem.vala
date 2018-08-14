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
    private File _file;
    public File file {
        get {
            return _file;
        } set {
            _file = value;
            title_label.label = file.get_basename ().replace (".spice", "");

            if (real_file) {
                set_tooltip_text (_("Open: %s").printf (file.get_path ()));
            } else {
                set_tooltip_text (_("Create Presentation"));
            }
        }
    }

    public string data { get; construct set; }

    private SlideWidget slide_widget;
    private Gtk.Popover? popover = null;
    private Gtk.Label title_label;

    private string last_aspect_ratio;

    public bool real_file { get; construct set; }

    public LibraryItem (File file, bool real_file) {
        Object (file: file, real_file: real_file);
        get_thumbnail ();
    }

    public LibraryItem.from_data (string data, string? file_name) {
        Object (data: data);

        title_label.label = file_name;
        load_thumbnail ();
    }

    construct {
        margin_top = 3;
        halign = Gtk.Align.CENTER;

        var event_box = new Gtk.EventBox ();
        event_box.events |= Gdk.EventMask.BUTTON_RELEASE_MASK;

        slide_widget = new SlideWidget ();
        slide_widget.show_button = real_file;
        slide_widget.settings_requested.connect (() => {
            show_popover ();
        });

        title_label = new Gtk.Label ("");
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        title_label.get_style_context ().add_class ("remove-padding");
        title_label.ellipsize = Pango.EllipsizeMode.END;
        title_label.halign = Gtk.Align.START;
        title_label.margin_start = 8;
        title_label.margin_end = 8;
        title_label.margin_bottom = 6;

        var box = new Gtk.Grid ();
        box.orientation = Gtk.Orientation.VERTICAL;
        box.add (slide_widget);
        box.add (title_label);

        event_box.add (box);
        add (event_box);

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
            name_entry.activate.connect (() => attempt_name_change(name_entry));

            var ratio_label = new Gtk.Label (_("Aspect Ratio: "));
            ratio_label.halign = Gtk.Align.END;

            var aspect_ratio = new Gtk.ComboBoxText ();
            aspect_ratio.append ("1", "4:3");
            aspect_ratio.append ("2", "16:9");
            aspect_ratio.append ("3", "16:10");
            aspect_ratio.append ("4", "3:2");
            aspect_ratio.append ("5", "5:4");

            last_aspect_ratio = "%d".printf (Utils.get_aspect_ratio (data));
            aspect_ratio.set_active_id (last_aspect_ratio);

            var location_button = new Gtk.Button.from_icon_name ("document-open-symbolic");
            location_button.get_style_context ().add_class ("flat");
            location_button.set_tooltip_text (_("Open file location…"));
            location_button.halign = Gtk.Align.START;

            location_button.clicked.connect (() => {
                popover.hide ();

                try {
                    AppInfo.launch_default_for_uri (file.get_parent ().get_uri (), null);
                } catch (Error e) {
                    warning ("No default app to open folders: %s", e.message);
                }
            });

            var grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.column_spacing = 6;
            grid.margin = 6;

            grid.attach (location_button, 0, 2, 1, 1);
            grid.attach (name_label, 0, 0, 1, 1);
            grid.attach (name_entry, 1, 0, 1, 1);
            grid.attach (ratio_label, 0, 1, 1, 1);
            grid.attach (aspect_ratio, 1, 1, 1, 1);

            grid.show_all ();

            popover = new Gtk.Popover (slide_widget);
            popover.position = Gtk.PositionType.LEFT;
            popover.add (grid);

            popover.closed.connect (() => {
                attempt_name_change(name_entry);

                if (aspect_ratio.get_active_id () != last_aspect_ratio) {
                    Spice.SlideManager.aspect_ratio_override = int.parse (aspect_ratio.get_active_id ());
                    activate ();
                }
            });
        }

        popover.show ();
    }

    private void attempt_name_change (Gtk.Entry name_entry) {
        var new_name = name_entry.get_text ().replace ("/", "") + ".spice";

        if (new_name != this.file.get_basename ()) {
            var path = this.file.get_parent ().get_path ();
            var new_file = File.new_for_path ("%s/%s".printf (path, new_name));

            if (new_file.query_exists ()) {
                window.add_toast_notification (new Granite.Widgets.Toast (_("Could not rename: File already exists…")));
                return;
            }

            FileUtils.rename (this.file.get_path (), new_file.get_path ());
            Spice.Services.Settings.get_instance ().add_file (new_file.get_path ());

            this.file = new_file;
        }
    }

    private void get_file_data () {
        data = Services.FileManager.get_presentation_data (file);
    }

    private void get_template_data () {
        var dis = new DataInputStream (file.read ());
        size_t size;

        data = dis.read_upto ("\0", -1, out size);
    }

    private void get_thumbnail () {
        if (file.query_exists ()) {
            new Thread<void*> ("content-loading", () => {
                if (real_file) {
                    get_file_data ();
                } else {
                    get_template_data ();
                }

                load_thumbnail ();

                return null;
            });
        }
    }

    private void load_thumbnail () {
        var pixbuf = Utils.base64_to_pixbuf (Utils.get_thumbnail_data (data));

        Idle.add (() => {
            slide_widget.pixbuf = pixbuf;
            return GLib.Source.REMOVE;
        });
    }
}
