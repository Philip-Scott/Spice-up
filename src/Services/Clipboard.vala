/*
* Copyright (c) 2018 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

public class Spice.Clipboard {
    const string SPICE_UP_TARGET_NAME = "x-application/spice-up-data";
    static Gdk.Atom SPICE_ATOM = Gdk.Atom.intern_static_string (SPICE_UP_TARGET_NAME);

    static Object? object_ref;
    static string? object_data;
    static bool set_internally = false;

    enum Target {
        STRING,
        IMAGE,
        SPICE
    }

    const Gtk.TargetEntry[] text_target_list = {
        { "text/plain", 0, Target.STRING },
        { "STRING", 0, Target.STRING },
        { SPICE_UP_TARGET_NAME, 0, Target.SPICE }
    };

    const Gtk.TargetEntry[] image_target_list = {
        { "image/png", 0, Target.IMAGE },
        { SPICE_UP_TARGET_NAME, 0, Target.SPICE }
    };

    const Gtk.TargetEntry[] spice_target_list = {
        { SPICE_UP_TARGET_NAME, 0, Target.SPICE }
    };

    public static void set_with_data (Gtk.Clipboard clipboard, Gtk.SelectionData selection_data, uint info, void* user_data_or_owner) {
        switch (info) {
            case Target.STRING:
                debug ("String requested\n");
                if (object_ref is Spice.TextItem) {
                    selection_data.set_text ((object_ref as Spice.TextItem).text, -1);
                }
                break;
            case Target.IMAGE:
                debug ("Image requested\n");
                if (object_ref is Spice.ImageItem) {
                    var image_item = object_ref as Spice.ImageItem;
                    var pixbuf = new Gdk.Pixbuf.from_file (image_item.image.url);
                    selection_data.set_pixbuf (pixbuf);
                } else if (object_ref is Gdk.Pixbuf) {
                    var pixbuf = (object_ref as Gdk.Pixbuf);
                    selection_data.set_pixbuf (pixbuf);
                }
                break;
            case Target.SPICE:
                debug ("Spice object requested\n");
                selection_data.@set (SPICE_ATOM, 0, object_data.data);
                break;
            default:
                debug ("Other data %u\n", info); break;
        }
    }

    public static void clear_data (Gtk.Clipboard clipboard, void* user_data_or_owner) {
        if (!set_internally) {
            object_ref = null;
            object_data = null;
        }

        set_internally = false;
    }

    public static void copy (Spice.SlideManager manager, Object object) {
        if (object == null) return;

        // Use the pase operation of the textItem
        if (object == manager.current_item && object is Spice.TextItem) {
            var text_entry = (object as Spice.TextItem).entry;
            if (text_entry.buffer.get_has_selection ()) {
                text_entry.copy_clipboard ();
                return;
            }
        }

        set_internally = true;

        Gtk.Clipboard clipboard = Gtk.Clipboard.get_default (Gdk.Display.get_default ());

        object_data = clone (object);

        if (object is Spice.TextItem) {
            debug ("set text target list");
            clipboard.set_with_data (text_target_list, set_with_data, clear_data, null);
        } else if (object is Spice.ImageItem || object is Spice.Slide) {
            debug ("set image target list");
            clipboard.set_with_data (image_target_list, set_with_data, clear_data, null);
        } else {
            clipboard.set_with_data (spice_target_list, set_with_data, clear_data, null);
        }

        if (object is Spice.CanvasItem) {
            object_ref = Utils.canvas_item_from_data (Utils.get_json_object (object_data), null);
        } else {
            object_ref = (object as Spice.Slide).canvas.surface.load_to_pixbuf ();
        }
    }

    public static void paste (Spice.SlideManager manager) {
        Gtk.Clipboard clipboard = Gtk.Clipboard.get_default (Gdk.Display.get_default ());

        Gdk.Atom[] targets;
        clipboard.wait_for_targets (out targets);

        Gdk.Atom? spice_atom = null;
        Gdk.Atom? text_atom = null;
        Gdk.Atom? image_atom = null;

        foreach (var target in targets) {
            debug ("%s\n", target.name ());
            switch (target.name ()) {
                case SPICE_UP_TARGET_NAME: spice_atom = target; break;
                case "text/plain": text_atom = target; break;
                case "image/png": image_atom = target; break;
            }
        }

        // Use the pase operation of the textItem
        if (text_atom != null && image_atom == null && manager.current_item is Spice.TextItem) {
            (manager.current_item as Spice.TextItem).entry.paste_clipboard ();
            return;
        }

        if (spice_atom != null) {
            clipboard.request_contents (spice_atom, (c, raw_data) => {
                var data = (string) raw_data.get_data ();
                if (data == null) return;

                var root_object = Utils.get_json_object (data);
                if (root_object == null) return;

                if (root_object.has_member ("preview")) {
                    manager.new_slide (root_object, true);
                } else {
                    var item = Utils.canvas_item_from_data (root_object, manager.current_slide.canvas);
                    manager.current_slide.add_item (item, true, true);
                }
            });
            return;
        } else if (image_atom != null) {
            clipboard.request_contents (image_atom, (c, raw_data) => {
                debug ("Getting image data");
                var pixbuf = raw_data.get_pixbuf ();
                if (pixbuf == null) return;

                var data = Utils.pixbuf_to_base64 (pixbuf);

                var item = new ImageItem.from_data (manager.current_slide.canvas, data, "png");
                manager.current_slide.add_item (item, true, true);
            });
        } else if (text_atom != null) {
            clipboard.request_contents (text_atom, (c, raw_data) => {
                debug ("Getting text data");
                var data = (string) raw_data.get_data ();
                if (data == null) return;

                var item = manager.request_new_item (Spice.CanvasItemType.TEXT);
                (item as Spice.TextItem).text = data;
            });
        } else {
            // Show an error instead of silently failing
            Spice.Application.get_active_spice_window ().add_toast_notification (new Granite.Widgets.Toast (_("Unknown clipboard data")));
        }
    }

    public static void cut (Spice.SlideManager manager, Object object) {
        if (object == null) return;

        if (object == manager.current_item && object is Spice.TextItem) {
            var text_entry = (object as Spice.TextItem).entry;
            if (text_entry.buffer.get_has_selection ()) {
                text_entry.cut_clipboard ();
                return;
            }
        }

        copy (manager, object);

        Clipboard.delete (object);
    }

    public static void delete (Object object) {
        if (object == null) return;

        if (object is Spice.CanvasItem) {
            (object as Spice.CanvasItem).delete ();
        } else if (object is Spice.Slide) {
            (object as Slide).delete ();
        }
    }

    public static string clone (Object object) {
        if (object == null) return "";

        if (object is Spice.CanvasItem) {
            return (object as Spice.CanvasItem).serialise ();
        } else if (object is Spice.Slide) {
            return (object as Slide).serialise ();
        } else {
            return "";
        }
    }

    public static void duplicate (Spice.SlideManager manager, Object object) {
        if (object == null) return;

        string data = clone (object);

        var root_object = Utils.get_json_object (data);
        if (root_object == null) return;

        if (object is Spice.CanvasItem) {
            var item = Utils.canvas_item_from_data (root_object, manager.current_slide.canvas);
            manager.current_slide.add_item (item, true, true);
        } else {
            manager.new_slide (root_object, true);
        }
    }
}