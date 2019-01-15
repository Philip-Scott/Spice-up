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
    public const string FILE_EXTENSION = ".spice";

    private static File? get_file_from_user (string title, string accept_button_label, Gtk.FileChooserAction chooser_action, List<Gtk.FileFilter> filters) {
        File? result = null;

        var dialog = new Gtk.FileChooserDialog (
            title,
            Spice.Application.get_active_spice_window (),
            chooser_action,
            _("Cancel"), Gtk.ResponseType.CANCEL,
            accept_button_label, Gtk.ResponseType.ACCEPT);

        var all_filter = new Gtk.FileFilter ();
        all_filter.set_filter_name ("All Files");
        all_filter.add_pattern ("*");

        filters.append (all_filter);

        filters.@foreach ((filter) => {
            dialog.add_filter (filter);
        });

        if (dialog.run () == Gtk.ResponseType.ACCEPT) {
            result = dialog.get_file ();
        }

        dialog.close ();

        return result;
    }

    public static File? open_image () {
        List<Gtk.FileFilter> filters = new List<Gtk.FileFilter> ();
        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.set_filter_name ("Images");
        filter.add_mime_type ("image/*");

        filters.append (filter);

        return get_file_from_user (_("Open Image"), _("Open"), Gtk.FileChooserAction.SAVE, filters);
    }

    public static File? open_presentation () {
        File? result = null;

        List<Gtk.FileFilter> filters = new List<Gtk.FileFilter> ();
        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.set_filter_name ("Presentation");
        filter.add_mime_type ("application/x-spiceup");

        filters.append (filter);

        result = get_file_from_user (_("Open file"), _("Open"), Gtk.FileChooserAction.OPEN, filters);

        return result;
    }

    public static File? new_presentation (string data) {
        File? result = null;

        var documents = Environment.get_user_special_dir (UserDirectory.DOCUMENTS) + "/%s".printf (_("Presentations"));

        if (documents != null) {
            DirUtils.create_with_parents (documents, 0775);
        } else {
            documents = Environment.get_home_dir ();
            if (documents == null) {
                documents = ".";
            }
        }

        int id = 1;
        do {
            result = File.new_for_path ("%s/%s %d%s".printf (documents, _("Untitled Presentation"), id++, FILE_EXTENSION));
        } while (result.query_exists ());

        settings.add_file (result.get_path ());

        var title = GLib.Base64.encode(_("My Presentation").data);
        var name = GLib.Base64.encode(_("By: %s").printf (Environment.get_real_name ()).data);

        var formatted_data = data.replace ("{title}", title).replace ("{subtitle}", name);

        GLib.FileUtils.set_data (result.get_path (), formatted_data.data);

        return result;
    }

    private static string? header = null;
    private static string? footer = null;
    private const string RESOURCE_PATH = "resource:///com/github/philip-scott/spice-up/%s";

    public static void write_file (File file, string contents) {
        if (file == null) {
            return;
        }

        if (file.query_exists ()) {
            try {
                file.delete ();
            } catch (Error e) {
                warning ("Could not delete file: %s", e.message);
            }
        }

        if (header == null) {
            var temp_file = File.new_for_uri (RESOURCE_PATH.printf ("save-header"));
            var dis = new DataInputStream (temp_file.read ());
            size_t size;

            header = dis.read_upto ("\0", -1, out size);
        }

        if (footer == null) {
            var temp_file = File.new_for_uri (RESOURCE_PATH.printf ("save-footer"));
            var dis = new DataInputStream (temp_file.read ());
            size_t size;

            footer = dis.read_upto ("\0", -1, out size);
        }

        create_file_if_not_exists (file);

        try {
            GLib.FileUtils.set_data (file.get_path (), (header + contents + footer).data);
        } catch (Error e) {
            warning ("Could not write file \"%s\": %s", file.get_basename (), e.message);
        }
    }

    public static string open_file (File file) {
        settings.add_file (file.get_path ());
        return get_presentation_data (file);
    }

    public static void delete_file (File file) {
        if (file != null
        && file.query_exists ()
        && file.get_basename ().contains (FILE_EXTENSION)) {
            FileUtils.remove (file.get_path ());
        }
    }

    public static string get_presentation_data (File file) {
        if (file != null && file.query_exists ()) {
            var data = get_data (file);
            if (data.get_char (0) == '<') {
                data = data.split ("""<content id="content">""")[1].split ("</content>")[0];
            }

            return data;
        }

        return "";
    }

    public static string get_data (File file) {
        string data = "";

        try {
            FileUtils.get_contents (file.get_path (), out data);
        } catch (Error e) {
            warning ("Error reading file: %s", e.message);
        }
        return data;
    }

    public static void create_file_if_not_exists (File file) {
        if (!file.query_exists ()) {
            try {
                file.create (FileCreateFlags.REPLACE_DESTINATION);
            } catch (Error e) {
                error ("Could not write file: %s", e.message);
            }
        }
    }

    public static void export_to_pdf (SlideManager manager) {
        List<Gtk.FileFilter> filters = new List<Gtk.FileFilter> ();
        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.set_filter_name ("PDF");
        filter.add_mime_type ("application/pdf");

        filters.append (filter);

        var file = get_file_from_user (_("Export to PDF"), _("Save"), Gtk.FileChooserAction.SAVE, filters);
        if (file == null) return;

        if (!file.get_basename ().down ().has_suffix (".pdf")) {
            file = File.new_for_path (file.get_path () + ".pdf");
        }

        var current_slide = manager.current_slide.canvas;
        Cairo.Surface pdf = new Cairo.PdfSurface (file.get_path (),
                                           current_slide.get_allocated_width (),
                                           current_slide.get_allocated_height ());
        int pages_to_draw = 1;
        foreach (var slide in manager.slides) {
            if (slide.canvas.surface == null || slide.canvas.get_allocated_width () != current_slide.get_allocated_width ()) {
                Timeout.add (500 * pages_to_draw++, () => {
                    manager.current_slide = slide;
                    manager.current_slide.canvas.queue_draw ();
                    return false;
                });
            }
        }

        Timeout.add (600 * pages_to_draw, () => {
            bool first = true;
            foreach (var slide in manager.slides) {
                if (!slide.visible) continue;

                if (!first) {
                    pdf.copy_page ();
                } else {
                    first = false;
                }

                var buffer = slide.canvas.surface;

                Cairo.Context pdfcontext = new Cairo.Context (pdf);
                pdfcontext.set_source_surface (buffer.surface, 0, 0);
                pdfcontext.paint ();
            }

            pdf.finish ();
            return false;
        });
    }

    public static string file_to_base64 (File file) {
        uint8[] data;

        try {
            FileUtils.get_data (file.get_path (), out data);
        } catch (Error e) {
            warning ("Could not get file data: %s", e.message);
        }

        return Base64.encode (data);
    }

    public static void base64_to_file (string filename, string base64_data) {
        var data = Base64.decode (base64_data);
        try {
           FileUtils.set_data (filename, data);
        } catch (Error e) {
            warning ("Could not save data to file: %s", e.message);
        }
    }
}
