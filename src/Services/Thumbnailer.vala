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

public class Spice.Services.Thumbnailer {
    private static int width;

    public static void run (List<File> files) {
        if (files.length () < 1) return;
        var input = files.nth_data (0);
        var output = files.nth_data (1);

        if (!input.query_exists ()) return;
        var data = Spice.Services.FileManager.get_contents (input);

        var preview_data = get_thumbnail_data (data);

        if (preview_data != "") {
            make_surface (preview_data, output);
        }
    }

    private static string get_thumbnail_data (string raw_json) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (raw_json);

            var root_object = parser.get_root ().get_object ();
            var slides_array = root_object.get_array_member ("slides");

            var ratio = (int) root_object.get_int_member ("aspect-ratio");
            width = Spice.AspectRatio.get_width_value (Spice.AspectRatio.get_mode (ratio));

            var slides = slides_array.get_elements ();
            if (slides.length () > 0) {
                var preview_data = slides.nth_data (0).get_object ().get_string_member ("preview");

                if (preview_data != null) return preview_data;
            }
        } catch (Error e) {
            error ("Error loading file: %s", e.message);
        }

        return "";
    }

    private static void make_surface (string data, File output_file) {
        var pixbuf = Utils.base64_to_pixbuf (data);
        pixbuf.scale_simple (width, SlideList.HEIGHT, Gdk.InterpType.BILINEAR);

        var surface = new Granite.Drawing.BufferSurface (width, SlideList.HEIGHT);
        Gdk.cairo_set_source_pixbuf (surface.context, pixbuf, 0, 0);
        surface.context.paint ();

        Spice.Services.FileManager.create_file_if_not_exists (output_file);
        surface.surface.write_to_png (output_file.get_path ());
    }
}
