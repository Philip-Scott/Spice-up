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

public class Spice.ColorItem : Spice.CanvasItem {
    public string background_color {get; set; default = "#e00"; }

    const string TEXT_STYLE_CSS = """
        .colored {
            background: %s;
        }
    """;

    public ColorItem (Canvas canvas, Json.Object? save_data = null) {
        base (canvas);

        this.save_data = save_data;

        load_data ();
        style ();
    }

    protected override string serialise_item () {
        string data = """
            "type": "color",
            "background_color": "%s"
         """.printf (background_color);


        return data;
    }

    protected override void load_item_data () {
        background_color = save_data.get_string_member ("background_color");
    }

    public override void style () {
        Utils.set_style (this, TEXT_STYLE_CSS.printf (background_color));
    }
}
