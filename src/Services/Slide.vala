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

    public string preview_data { get; private set; default = ""; }
    public string notes { get; set; default = ""; }

    private bool visible_ = true;
    public bool visible {
        get {
            return visible_;
        } set {
            this.visible_ = value;
            canvas.visible = value;
            visible_changed (value);
        }

        default = true;
    }

    public Slide (Json.Object? save_data = null) {
        this.save_data = save_data;
        canvas = new Spice.Canvas (save_data);
        preview = new Gtk.Image ();

        canvas.request_draw_preview.connect (reload_preview_data);
        load_data ();
    }

    public void load_slide () {
        if (save_data == null) return;
        canvas.clear_all ();

        var items = save_data.get_array_member ("items");

        foreach (var raw in items.get_elements ()) {
            var item = raw.get_object ();

            add_item_from_data (item);
        }

        this.save_data = null;
    }

    private void load_data () {
        if (save_data == null) return;

        preview_data = save_data.get_string_member ("preview");
        if (preview_data != null && preview_data != "") {
            var pixbuf = Utils.base64_to_pixbuf (preview_data);

            preview.set_from_pixbuf (pixbuf.scale_simple (SlideList.WIDTH, SlideList.HEIGHT, Gdk.InterpType.BILINEAR));
        }

        var raw_notes = save_data.get_string_member ("notes");
        if (raw_notes != null && raw_notes != "") {
            notes = (string) GLib.Base64.decode (raw_notes);
        }
    }

    public void add_item_from_data (Json.Object data, bool select_item = false, bool save_history = false) {
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

        if (item != null) {
            canvas.add_item (item, save_history);

            if (select_item) {
                canvas.item_clicked (item);
                item.clicked ();
            }
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

    public string serialise () {
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

        var raw_notes = (string) GLib.Base64.encode (notes.data);
        return "{%s, \"items\": [%s], \"notes\": \"%s\", \"preview\": \"%s\"}\n".printf (canvas.serialise (), data, raw_notes, preview_data);
    }

    public void delete () {
        var action = new Spice.Services.HistoryManager.HistoryAction<Slide,bool>.slide_changed (this, "visible");
        Spice.Services.HistoryManager.get_instance ().add_undoable_action (action, true);

        this.visible = false;
    }

    public void destroy () {
        canvas.destroy ();
    }
}
