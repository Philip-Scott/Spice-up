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

public class Spice.Slide : Object {
    public signal void visible_changed (bool val);

    protected Json.Object? save_data = null;

    public Canvas canvas;
    public Gtk.Image preview;

    private File? thumbnail_file = null;
    public string preview_data { get; private set; default = ""; }
    public string notes { get; set; default = ""; }
    public Gtk.StackTransitionType transition { get; set; default = Gtk.StackTransitionType.NONE; }

    private bool is_empty_last_slide = false;

    private Gee.LinkedList<Spice.CanvasItem> to_be_deleted = new Gee.LinkedList<Spice.CanvasItem>();
    private bool visible_ = true;
    public bool visible {
        get {
            return visible_;
        } set {
            this.visible_ = value;
            canvas.visible = value;
            visible_changed (value);

            if (value) {
                foreach (var item in to_be_deleted) {
                    item.visible = true;
                }

                if (!is_empty_last_slide) {
                    canvas.window.current_file.file_collector.ref_file (thumbnail_file);
                }

                to_be_deleted.clear ();
            } else {
                if (!is_empty_last_slide) {
                    canvas.window.current_file.file_collector.unref_file (thumbnail_file);
                }

                foreach (var widget in canvas.get_children ()) {
                    if (widget is CanvasItem && widget.visible) {
                        CanvasItem item = (CanvasItem) widget;
                        item.visible = false;
                        to_be_deleted.add (item);
                    }
                }
            }
        }
    }

    public Slide (Spice.Window window, Json.Object? save_data = null) {
        this.save_data = save_data;
        canvas = new Spice.Canvas (window, save_data);

        canvas.request_draw_preview.connect (reload_preview_data);
        load_data ();
    }

    public Slide.empty (Spice.Window window) {
        this.save_data = Utils.get_json_object (EMPTY_SLIDE);
        is_empty_last_slide = true;

        canvas = new Spice.Canvas (window, save_data);

        load_data ();
        visible = false;
    }

    public Slide.without_canvas (Json.Object? save_data = null) {
        this.save_data = save_data;
        canvas = null;

        load_data ();
    }

    construct {
        preview = new Gtk.Image ();
    }

    public void load_slide () {
        if (save_data == null) return;
        canvas.clear_all ();

        var items = save_data.get_array_member ("items");

        foreach (var raw in items.get_elements ()) {
            var item = Utils.canvas_item_from_data (raw.get_object (), canvas);
            add_item (item);
        }

        this.save_data = null;
    }

    private void load_data () {
        if (save_data == null) return;

        if (save_data.has_member ("preview")) {
            preview_data = save_data.get_string_member ("preview");

            if (preview_data != null && preview_data != "") {
                var pixbuf = Utils.base64_to_pixbuf (preview_data);

                preview.set_from_pixbuf (pixbuf.scale_simple (SlideList.WIDTH, SlideList.HEIGHT, Gdk.InterpType.BILINEAR));
            }
        } else if (save_data.has_member ("thumbnail")) {
            var thumbnail_basename = save_data.get_string_member ("thumbnail");
            if (canvas != null && thumbnail_basename != "") {
                var current_file = canvas.window.current_file;
                thumbnail_file = current_file.get_file_from_basename (current_file.thumbnails_folder, thumbnail_basename);

                var pixbuf = new Gdk.Pixbuf.from_file (thumbnail_file.get_path ());
                preview.set_from_pixbuf (pixbuf);
            }
        }

        if (!is_empty_last_slide && canvas != null) {
            if (thumbnail_file == null) {
                var current_file = canvas.window.current_file;
                thumbnail_file = current_file.get_random_file_name (current_file.thumbnails_folder, "jpg");
            }

            canvas.window.current_file.file_collector.ref_file (thumbnail_file);
        }

        if (save_data.has_member ("transition")) {
            transition = (Gtk.StackTransitionType) save_data.get_int_member ("transition");
        } else {
            transition = Gtk.StackTransitionType.NONE;
        }

        var raw_notes = save_data.get_string_member ("notes");
        if (raw_notes != null && raw_notes != "") {
            notes = (string) GLib.Base64.decode (raw_notes);
        }
    }

    public void add_item (CanvasItem item, bool select_item = false, bool save_history = false) {
        canvas.add_item (item, save_history);

        if (select_item) {
            canvas.item_clicked (item);
            item.clicked ();
        }
    }

    public void reload_preview_data () {
        Timeout.add (110, () => {
            if (canvas.surface != null) {
                var pixbuf = canvas.surface.load_to_pixbuf ().scale_simple (SlideList.WIDTH, SlideList.HEIGHT, Gdk.InterpType.BILINEAR);
                preview.set_from_pixbuf (pixbuf);
                preview_data = Utils.pixbuf_to_base64 (pixbuf);
            }

            return false;
        });
    }

    public string serialise (bool save_preview = false) {
        if (this.save_data != null) {
            var root = new Json.Node (Json.NodeType.OBJECT);
            root.set_object (save_data);

            var gen = new Json.Generator ();
            gen.set_root (root);

            return gen.to_data (null);
        }

        string data = "";

        foreach (var widget in canvas.get_children ()) {
            if (widget is CanvasItem && widget.visible) {
                CanvasItem item = (CanvasItem) widget;

                data = data + (data != "" ? "," + item.serialise () : item.serialise ());
            }
        }

        if (save_preview && thumbnail_file != null) {
            print ("Saving thumbnail at %s\n", thumbnail_file.get_path ());
            try {
                preview.pixbuf.save (thumbnail_file.get_path (), "jpeg");
            } catch (Error e) {
                warning (e.message);
            }
        }

        string preview_name = save_preview && thumbnail_file != null ? thumbnail_file.get_basename () : "";
        var raw_notes = (string) GLib.Base64.encode (notes.data);

        return "{%s, \"transition\": %d, \"items\": [%s], \"notes\": \"%s\", \"thumbnail\": \"%s\" }\n".printf (canvas.serialise (), (int) transition, data, raw_notes, preview_name);
    }

    public void delete () {
        var action = new Spice.Services.HistoryManager.HistoryAction<Slide,bool>.slide_changed (this, "visible");
        canvas.window.history_manager.add_undoable_action (action, true);

        this.visible = false;
    }

    public void destroy () {
        canvas.destroy ();
    }

    private const string EMPTY_SLIDE = """{"background-color":"#000000", "background-pattern":"" , "items": [{"x": 0,"y": 0,"w": 720,"h": 510, "type": "color", "background_color": "#000000", "border-radius": 0 }], "notes":"", "preview": "iVBORw0KGgoAAAANSUhEUgAAAQsAAACWCAYAAADJ2q17AAAABmJLR0QA/wD/AP+gvaeTAAACM0lEQVR4nO3UMWpbURQAUd3Hlwpt1qndxztOVOjDcx8ITCcZzlnBVDNrrY/jOL5m5n4B+Mfe+3Ge5+fcbrc/z+fzvvd+dRPwhmbmcr1e/66ZMQrgv/bel5m5r1eHAD+DWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQCJWQDJ2ns/ZubVHcCbmpnL3vsxa61fx3H8npn7q6OA97P3fpzn+fkNRKooH6vPau0AAAAASUVORK5CYII="}""";
}
