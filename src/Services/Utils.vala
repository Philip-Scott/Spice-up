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

public class Spice.Utils {

    private const string[] ACCEPTED_TYPES = {
        "image/jpeg",
        "image/png",
        "image/tiff",
        "image/svg+xml",
        "image/gif"
    };

    public static Gdk.Pixbuf base64_to_pixbuf (string base64) {
        var raw_data = GLib.Base64.decode (base64);
        var loader = new Gdk.PixbufLoader ();
        loader.write (raw_data);
        loader.close ();

        return loader.get_pixbuf ();
    }

    public static string pixbuf_to_base64 (Gdk.Pixbuf pixbuf) {
        var w = pixbuf.get_width();
        var h = pixbuf.get_height();

        var surface = new Granite.Drawing.BufferSurface (w, h);
        Gdk.cairo_set_source_pixbuf (surface.context, pixbuf, 0, 0);
        surface.context.paint ();

        return surface_to_base64 (surface.surface);
    }

    public static string surface_to_base64 (Cairo.Surface surface) {
        var data_raw = new Array<uchar>();
        surface.write_to_png_stream ((raw) => {
            data_raw.append_vals (raw, raw.length);
            return Cairo.Status.SUCCESS;
        });

        return GLib.Base64.encode (data_raw.data);
    }

    // Check if the filename has a picture file extension.
    public static bool is_valid_image (GLib.File file) {
        var file_info = file.query_info ("standard::*", 0);

        // Check for correct file type, don't try to load directories and such
        if (file_info.get_file_type () != GLib.FileType.REGULAR) {
            return false;
        }

        foreach (var type in ACCEPTED_TYPES) {
            if (GLib.ContentType.equals (file_info.get_content_type (), type)) {
                return true;
            }
        }

        return false;
    }

    public static void set_style (Gtk.Widget widget, string css) {
        try {
            var provider = new Gtk.CssProvider ();
            var context = widget.get_style_context ();

            provider.load_from_data (css, css.length);

            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Style error: %s", e.message);
            stderr.printf ("%s %s\n", widget.name, css);
        }
    }

    public static void set_cursor (Gdk.CursorType cursor_type) {
        var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), cursor_type);
        window.get_screen ().get_active_window ().set_cursor (cursor);
    }
}
