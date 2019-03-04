/*
 *  Copyright (C) 2019 Felipe Escoto <felescoto95@hotmail.com>
 *
 *  This program or library is free software; you can redistribute it
 *  and/or modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General
 *  Public License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301 USA.
 */

public class Spice.FileFormat.CanvasItem : JsonObject {

    public string item_type { get; set; }
    public int x { get; set; default = 0; }
    public int y { get; set; default = 0; }
    public int w { get; set; default = 720; }
    public int h { get; set; default = 510; }

    public override string key_override (string key) {
        if (key == "item-type") return "type";
        return key;
    }
}

public class Spice.FileFormat.ColorItem : Spice.FileFormat.CanvasItem {
    public string background_color { get; set; default = "linear-gradient(to bottom, #e00 0%, #e00 100%);"; }
    public int border_radius { get; set; default = 0; }

    public override string key_override (string key) {
        if (key == "item-type") return "type";
        else if (key == "background-color") return "background_color";

        return key;
    }
}

public class Spice.FileFormat.TextItem : Spice.FileFormat.CanvasItem {
    public string text_data { get; set; default = ""; }
    public string font { get; set; default = "Open Sans"; }
    public string color { get; set; default = "#f00"; }
    public int font_size { get; set; default = 16; }
    public string font_style { get; set; default = "Regular"; }
    public int justification { get; set; default = 1; }
    public int align { get; set; default = 1; }

    public string text {
        set {
            if (value != "")
            text_data = Base64.encode (value.data);
        }
    }
}

public class Spice.FileFormat.ImageItem : Spice.FileFormat.CanvasItem {
    public string archived_image { get; set; default = ""; }


    // Deprecated properties
    public string image_data { get; set; default = ""; }
    public string image { get; set; default = ""; }
}

public class Spice.FileFormat.CanvasItemArray : FileFormat.JsonObjectArray {
    public Gee.LinkedList<CanvasItem>? elements = null;

    public CanvasItemArray (Json.Object object, string property_name) {
        Object (
            object: object,
            property_name: property_name
        );
    }

    protected override void load_array () {
        if (elements == null) {
            elements = new Gee.LinkedList<CanvasItem>();
        }

        object.get_array_member (property_name).get_elements ().foreach ((node) => {
            var object = node.get_object ();
            var object_type = object.get_string_member ("type");

            add_to_list (new_canvas_item (object, object_type));
        });
    }

    public static FileFormat.CanvasItem new_canvas_item (Json.Object json, string type) {
        switch (type) {
            case "color":
                return (FileFormat.CanvasItem) Object.new (
                    typeof (Spice.FileFormat.ColorItem),
                    "object", json,
                    "parent-object", null);
            case "text":
                return (FileFormat.CanvasItem) Object.new (
                    typeof (Spice.FileFormat.TextItem),
                    "object", json,
                    "parent-object", null);
            case "image":
                return (FileFormat.CanvasItem) Object.new (
                    typeof (Spice.FileFormat.ImageItem),
                    "object", json,
                    "parent-object", null);
            default:
            break;
        }

        assert_not_reached ();
    }

    public override void add_to_list (JsonObject json_object) {
        elements.add ((CanvasItem) json_object);
    }

    public override Type get_type_of_array () {
        return typeof (Spice.FileFormat.CanvasItem);
    }
}