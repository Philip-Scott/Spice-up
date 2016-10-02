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

public class Spice.Services.FileManager {
    public static File? current_file;

    public static File? get_file_from_user (bool image = false, bool save = false) {
        File? result = null;

        string title = "";
        Gtk.FileChooserAction chooser_action = Gtk.FileChooserAction.SAVE;
        string accept_button_label = "";
        List<Gtk.FileFilter> filters = new List<Gtk.FileFilter> ();

        if (save) {
            title =  _("Save file");
            accept_button_label = _("Save");
        } else {
            title =  _("Open file");
            chooser_action = Gtk.FileChooserAction.OPEN;
            accept_button_label = _("Open");
        }

        var filter = new Gtk.FileFilter ();
        if (image) {
            filter.set_filter_name ("Images");
            filter.add_mime_type ("image/*");
        } else if (save) {
            filter.set_filter_name ("Presentation");
            filter.add_mime_type ("application/x-spice");
        }

        filters.append (filter);

        var all_filter = new Gtk.FileFilter ();
        all_filter.set_filter_name ("All Files");
        all_filter.add_pattern ("*");

        filters.append (all_filter);

        var dialog = new Gtk.FileChooserDialog (
            title,
            window,
            chooser_action,
            _("Cancel"), Gtk.ResponseType.CANCEL,
            accept_button_label, Gtk.ResponseType.ACCEPT);


        filters.@foreach ((filter) => {
            dialog.add_filter (filter);
        });

        if (dialog.run () == Gtk.ResponseType.ACCEPT) {
            result = dialog.get_file ();
        }

        dialog.close ();

        return result;
    }

    public static void write_file (string contents) throws Error {
        if (current_file.query_exists ()) {
            current_file.delete ();
        }

        create_file_if_not_exists (current_file);

        current_file.open_readwrite_async.begin (Priority.DEFAULT, null, (obj, res) => {
            try {
                var iostream = current_file.open_readwrite_async.end (res);
                var ostream = iostream.output_stream;
                ostream.write_all (contents.data, null);
            } catch (Error e) {
                warning ("Could not write file \"%s\": %s", current_file.get_basename (), e.message);
            }
        });
    }

    public static string open_file () throws Error {
        if (current_file.query_exists ()) {
            try {
                var dis = new DataInputStream (current_file.read ());
                size_t size;
                return dis.read_upto ("\0", -1, out size);
            } catch (Error e) {
                warning ("Error loading file: %s", e.message);
            }
        }

        return "";
    }

    public static void create_file_if_not_exists (File file) throws Error{
        if (!file.query_exists ()) {
            try {
                file.create (FileCreateFlags.REPLACE_DESTINATION);
            } catch (Error e) {
                throw new Error (Quark.from_string (""), -1, "Could not write file: %s", e.message);
            }
        }
    }
}
