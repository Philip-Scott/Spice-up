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

    private string preview_data = "";

    private bool visible_ = true;
    public bool visible {
        get {
            return visible_;
        } set {
            visible_changed (value);
            this.visible_ = value;
            canvas.visible = value;
        }

        default = true;
    }

    public Slide (Json.Object? save_data = null) {
        this.save_data = save_data;
        canvas = new Spice.Canvas (save_data);
        preview = new Gtk.Image ();

        load_data (save_data);

        canvas.item_clicked.connect ((item) => {reload_preview_data ();});
    }

    public void load_data (Json.Object? save_data) {
        if (save_data == null) return;
        canvas.clear_all ();

        var items = save_data.get_array_member ("items");

        foreach (var raw in items.get_elements ()) {
            var item = raw.get_object ();

            string type = item.get_string_member ("type");

            switch (type) {
                case "text":
                    canvas.add_item (new TextItem (canvas, item), true);
                break;
                case "color":
                    canvas.add_item (new ColorItem (canvas, item), true);
                break;
                case "image":
                    canvas.add_item (new ImageItem (canvas, item), true);
                break;
            }
        }

        preview_data = save_data.get_string_member ("preview");
        if (preview_data != null && preview_data != "") {
            var pixbuf = Utils.base64_to_pixbuf (preview_data);

            preview.set_from_pixbuf (pixbuf.scale_simple (SlideList.WIDTH, SlideList.HEIGHT, Gdk.InterpType.BILINEAR));
        }
    }

    public void reload_preview_data () {
        if (canvas.surface != null) {
            var pixbuf = canvas.surface.load_to_pixbuf ().scale_simple (SlideList.WIDTH, SlideList.HEIGHT, Gdk.InterpType.BILINEAR);

            preview.set_from_pixbuf (pixbuf);
            preview_data = Utils.pixbuf_to_base64 (pixbuf);
        }
    }

    public string serialise () {
        string data = "";

        foreach (var widget in canvas.get_children ()) {
            if (widget is CanvasItem && widget.visible) {
                CanvasItem item = (CanvasItem) widget;

                data = data + (data != "" ? "," + item.serialise () : item.serialise ());
            }
        }

        return """{%s, "items": [%s], "preview": "%s"}""".printf (canvas.serialise (), data, preview_data);
    }

    public void delete () {
        var action = new Spice.Services.HistoryManager.HistoryAction<Slide,bool>.slide_changed (this, "visible");
        Spice.Services.HistoryManager.get_instance ().add_undoable_action (action, true);

        this.visible = false;
    }
}
