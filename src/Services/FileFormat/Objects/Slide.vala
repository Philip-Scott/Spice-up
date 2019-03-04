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

public class Spice.FileFormat.Slide : JsonObject {
    public string background_color { get; set; default = "#FFFFFF"; }
    public string background_pattern { get; set; default = ""; }
    public string notes { get; set; default = ""; }
    public string thumbnail { get; set; default = ""; }
    public int transition { get; set; default = 0; }

    public CanvasItemArray items { get; set; }

    public Slide (Json.Object object) {
        Object (object: object);
    }

    // Legacy Properties:
    public string preview { get; set; default = ""; }
}

public class Spice.FileFormat.SlideArray : FileFormat.JsonObjectArray {
    public Gee.LinkedList<Slide>? elements = null;

    public SlideArray (Json.Object object, string property_name) {
        Object (
            object: object,
            property_name: property_name
        );
    }

    public override void add_to_list (JsonObject json_object) {
        if (elements == null) {
            elements = new Gee.LinkedList<Slide>();
        }
        elements.add ((Slide) json_object);
    }

    public override Type get_type_of_array () {
        return typeof (Spice.FileFormat.Slide);
    }
}