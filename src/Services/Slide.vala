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

public class Spice.Slide {

    protected Json.Object? save_data = null;

    public Canvas canvas;
    public Canvas preview;

    public Slide (Json.Object? save_data = null, string? temp_data = null) {
        this.save_data = save_data;
        canvas = new Spice.Canvas ();
        preview = new Spice.Canvas.preview ();

        if (temp_data == null) {
            load_data (TESTING_DATA);
        } else {
            load_data (temp_data);
        }
    }

    public void load_data (string data, bool preview_only = false) {
        preview.clear_all ();
        if (!preview_only) {
            canvas.clear_all ();
        }
    
        var parser = new Json.Parser ();
        parser.load_from_data (data);

        var root_object = parser.get_root ().get_object ();
        var items = root_object.get_array_member ("items");

        foreach (var raw in items.get_elements ()) {
            var item = raw.get_object ();

            string type = item.get_string_member ("type");

            switch (type) {
                case "text":
                    if (!preview_only) canvas.add_item (new TextItem (canvas, item));
                    preview.add_item (new TextItem (preview, item));
                break;
                case "color":
                    if (!preview_only) canvas.add_item (new ColorItem (canvas, item));
                    preview.add_item (new ColorItem (preview, item));
                break;
            }
        }
    }

    public string serialise () {
        string data = "";

        foreach (var widget in canvas.get_children ()) {
            if (widget is CanvasItem) {
                CanvasItem item = (CanvasItem) widget;

                data = data + (data != "" ? "," + item.serialise () : item.serialise ());
            }
        }

        return """{"items": [%s]}""".printf (data);
    }

    private const string TESTING_DATA = """
{"items": [ {
              "x": -313,
              "y": -76,
              "w": 2203,
              "h": 1731,

           "type": "color",
           "background_color": "rgb(114,159,207)"

              }
       , {
              "x": -354,
              "y": 970,
              "w": 1925,
              "h": 122,

           "type": "color",
           "background_color": "rgb(252,233,79)"

              }
       , {
              "x": -280,
              "y": 458,
              "w": 1897,
              "h": 336,

           "type":"text",
           "text": "New Presentation",
           "font": "Raleway Medium 10",
           "color": "rgb(255,255,255)",
           "font-size": 42

              }
       , {
              "x": -339,
              "y": 702,
              "w": 902,
              "h": 300,

           "type":"text",
           "text": "By Felipe Escoto",
           "font": "Open Sans",
           "color": "rgb(255,255,255)",
           "font-size": 18

              }
       ]}
    """;
}
