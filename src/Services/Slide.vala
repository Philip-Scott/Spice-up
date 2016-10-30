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
    public Canvas preview;

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
        preview = new Spice.Canvas.preview (save_data);

        load_data (save_data);
    }

    public void load_data (Json.Object? save_data, bool load_canvas = true) {
        if (save_data == null) return;
        if (load_canvas) canvas.clear_all ();

        var items = save_data.get_array_member ("items");

        foreach (var raw in items.get_elements ()) {
            var item = raw.get_object ();

            string type = item.get_string_member ("type");

            switch (type) {
                case "text":
                    if (load_canvas) canvas.add_item (new TextItem (canvas, item), true);
                    preview.add_item (new TextItem (preview, item));
                break;
                case "color":
                    if (load_canvas) canvas.add_item (new ColorItem (canvas, item), true);
                    preview.add_item (new ColorItem (preview, item));
                break;
                case "image":
                    if (load_canvas) canvas.add_item (new ImageItem (canvas, item), true);
                    preview.add_item (new ImageItem (preview, item));
                break;
            }
        }
    }

    public void reload_preview_data () {
        string data = serialise ();
        var parser = new Json.Parser ();
        parser.load_from_data (data);
        var root_object = parser.get_root ().get_object ();

        preview.clear_all ();

        load_data (root_object, false);

        preview.save_data = root_object;
        preview.load_data ();
        preview.style ();
    }

    public string serialise () {
        string data = "";

        foreach (var widget in canvas.get_children ()) {
            if (widget is CanvasItem && widget.visible) {
                CanvasItem item = (CanvasItem) widget;

                data = data + (data != "" ? "," + item.serialise () : item.serialise ());
            }
        }

        return """{%s, "items": [%s]}""".printf (canvas.serialise (), data);
    }
}
