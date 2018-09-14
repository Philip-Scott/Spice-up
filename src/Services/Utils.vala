/*
* Copyright (c) 2016-2017 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

    public static string get_thumbnail_data (string raw_json) {
        var root_object = get_json_object (raw_json);
        var slides_array = root_object.get_array_member ("slides");
        var preview_index = 0;

        if (root_object.has_member ("preview-slide")) {
            preview_index = (int) root_object.get_int_member ("preview-slide");
        }

        var slides = slides_array.get_elements ();
        if (preview_index > slides.length ()) preview_index = 0;

        if (slides.length () > 0) {

            var preview_data = slides.nth_data (preview_index).get_object ().get_string_member ("preview");

            if (preview_data != null) {
                return preview_data;
            }
        }

        return "";
    }

    public static int get_aspect_ratio (string raw_json) {
        var root_object = get_json_object (raw_json);
        return (int) root_object.get_int_member ("aspect-ratio");
    }

    public static Json.Object? get_json_object (string raw_json) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (raw_json);

            var root_object = parser.get_root ().get_object ();

            return root_object;
        } catch (Error e) {
            return null;
        }
    }

    public static Gdk.Pixbuf base64_to_pixbuf (string base64) {
        var raw_data = GLib.Base64.decode (base64);
        var loader = new Gdk.PixbufLoader ();

        try {
            loader.write (raw_data);
            loader.close ();
        } catch (Error e) {
            warning ("Loading image failed: %s", e.message);
        }

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
        try {
            var file_info = file.query_info ("standard::*", 0);

            // Check for correct file type, don't try to load directories and such
            if (file_info.get_file_type () != GLib.FileType.REGULAR) {
                return false;
            }
            try {
                var pixbuf = new Gdk.Pixbuf.from_file (file.get_path ());
                var width = pixbuf.get_width ();
                var height = pixbuf.get_height ();

                if (width < 1 || height < 1) return false;
            } catch (Error e) {
                warning ("Invalid image loaded: %s", e.message);
                return false;
            }

            foreach (var type in ACCEPTED_TYPES) {
                if (GLib.ContentType.equals (file_info.get_content_type (), type)) {
                    return true;
                }
            }
        } catch (Error e) {
            warning ("Could not get file info: %s", e.message);
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
            debug ("%s %s\n", widget.name, css);
        }
    }

    public static void set_cursor (string cursor_type) {
        var cursor = new Gdk.Cursor.from_name (Gdk.Display.get_default (), cursor_type);
        window.get_screen ().get_active_window ().set_cursor (cursor);
    }


    enum Target {
        STRING,
        IMAGE,
        SPICE
    }

    const string SPICE_UP_TARGET_NAME = "x-application/spice-up-data";
    const Gtk.TargetEntry[] target_list = {
        { "text/plain", 0, Target.STRING },
        { "STRING", 0, Target.STRING },
        { "image/png", 0, Target.IMAGE },
        { SPICE_UP_TARGET_NAME, 0, Target.SPICE }
    };

    static weak Object object_ref;
    public static void copy (Object object) {
        if (object == null) return;

        Gtk.Clipboard clipboard = Gtk.Clipboard.get_default (Gdk.Display.get_default ());
        object_ref = object;
        if (object_ref == null) debug ("is null\n");

        clipboard.set_with_data (target_list, set_with_data, null, null);
    }

    public static void set_with_data (Gtk.Clipboard clipboard, Gtk.SelectionData selection_data, uint info, void* user_data_or_owner) {
        switch (info) {
            case Target.STRING:
                debug ("String requested\n");
                if (object_ref is Spice.TextItem) {
                    selection_data.set_text ((object_ref as Spice.TextItem).text, -1);
                }
                break;
            case Target.IMAGE:
                debug ("Image requested\n"); break;
            case Target.SPICE:
                debug ("Spice requested\n");
                if (object_ref is Spice.CanvasItem) {
                    debug ("canvas item\n");
                    selection_data.@set (spice_atom, 0, (object_ref as Spice.CanvasItem).serialise ().data);
                } else if (object_ref is Spice.Slide) {
                    debug ("slide\n");
                    selection_data.@set (spice_atom, 0, (object_ref as Slide).serialise ().data);
                } else {
                    return;
                }
                break;
            default:
                debug ("Other data %u\n", info); break;
        }
    }

    static Gdk.Atom spice_atom = Gdk.Atom.intern_static_string ("x-application/spice-up-data");

    public static Spice.CanvasItem? canvas_item_from_data (Json.Object data, Spice.Canvas canvas) {
        string type = data.get_string_member ("type");
        CanvasItem? item = null;

        switch (type) {
            case "text":
                item = new TextItem (canvas, data);
            break;
            case "color":
                item = new ColorItem (canvas, data);
            break;
            case "image":
                item = new ImageItem (canvas, data);
            break;
        }

        return item;
    }

    public static void paste (Spice.SlideManager manager) {
        Gtk.Clipboard clipboard = Gtk.Clipboard.get_default (Gdk.Display.get_default ());
        bool is_image = clipboard.wait_is_image_available ();

        Gdk.Atom[] targets;
        clipboard.wait_for_targets (out targets);

        Gdk.Atom? spice_atom = null;
        foreach (var target in targets) {
            debug ("%s\n", target.name());
            if (target.name () == SPICE_UP_TARGET_NAME) {
                spice_atom = target;
                //break;
            }
        }

        if (spice_atom != null) {
            clipboard.request_contents (spice_atom, (c, raw_data) => {
                var data = (string) raw_data.get_data ();
                if (data == null) return;

                var root_object = get_json_object (data);
                if (root_object == null) return;

                if (root_object.has_member ("preview")) {
                    manager.new_slide (root_object, true);
                } else {
                    var item = canvas_item_from_data (root_object, manager.current_slide.canvas);
                    manager.current_slide.add_item (item, true, true);
                }
            });
            return;
        }

        // TODO: Handle other types of data, such as Text, images and more
    }

    public static void cut (Object object) {
        if (object == null) return;
        Utils.copy (object);
        Utils.delete (object);
    }

    public static void delete (Object object) {
        if (object == null) return;

        if (object is Spice.CanvasItem) {
            (object as Spice.CanvasItem).delete ();
        } else if (object is Spice.Slide) {
            (object as Slide).delete ();
        }
    }

    public static void duplicate (Object object, Spice.SlideManager manager) {
        if (object == null) return;

        string data;

        if (object is Spice.CanvasItem) {
            data = (object as Spice.CanvasItem).serialise ();
        } else if (object is Spice.Slide){
            data = (object as Slide).serialise ();
        } else {
            return;
        }

        var root_object = get_json_object (data);
        if (root_object == null) return;

        if (object is Spice.CanvasItem) {
            var item = canvas_item_from_data (root_object, manager.current_slide.canvas);
            manager.current_slide.add_item (item, true, true);
        } else {
            manager.new_slide (root_object, true);
        }
    }

    public static void new_slide (Spice.SlideManager manager) {
        manager.making_new_slide = true;

        var slide = manager.new_slide (null, true);
        slide.reload_preview_data ();
        manager.current_slide = slide;

        manager.making_new_slide = false;
    }
}

public enum Spice.AspectRatio {
    ASPECT_4_3 = 1,
    ASPECT_16_9 = 2,
    ASPECT_16_10 = 3,
    ASPECT_3_2 = 4,
    ASPECT_5_4 = 5;

    public static Spice.AspectRatio get_mode (int? value) {
        switch (value) {
            case 1: return ASPECT_4_3;
            case 2: return ASPECT_16_9;
            case 3: return ASPECT_16_10;
            case 4: return ASPECT_3_2;
            case 5: return ASPECT_5_4;
        }

        // get current aspect ratio if none was set
        var h = Gdk.Screen.height ();
        var w = Gdk.Screen.width ();

        var ratio = (int) ((double) w / h * 10);

        switch (ratio) {
            case 12: return ASPECT_5_4;
            case 13: return ASPECT_4_3;
            case 14: return ASPECT_3_2;
            case 16: return ASPECT_16_10;
            case 17: return ASPECT_16_9;
        }

        return ASPECT_16_9;
    }

    public static float get_ratio_value (Spice.AspectRatio value) {
        switch (value) {
            case ASPECT_4_3: return 1.3333f;
            case ASPECT_16_9: return 1.7777f;
            case ASPECT_16_10: return 1.6666f;
            case ASPECT_3_2: return 1.5f;
            case ASPECT_5_4: return 1.25f;
        }
        assert_not_reached();
    }

    public static int get_width_value (Spice.AspectRatio value) {
        switch (value) {
            case ASPECT_4_3: return 200;
            case ASPECT_16_9: return 267;
            case ASPECT_16_10: return 250;
            case ASPECT_3_2: return 225;
            case ASPECT_5_4: return 187;
        }
        assert_not_reached();
    }
}
