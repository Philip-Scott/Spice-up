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

public class Spice.ImageItem : Spice.CanvasItem {
    const string IMAGE_STYLE_CSS = """
        .colored {
            background-color: transparent;
            background-image: url("%s");
            background-position: center;
            background-size: contain;
            background-repeat: no-repeat;
        }
    """;
    const string IMAGE_MISSING_CSS = """
        .colored {
           border: 4px dashed #000000;
           border-color: #c92e34;
        }""";

    private bool valid = false;

    private string uri_ = "";
    public string uri {
        get {
            return uri_;
        } set {
            uri_ = value;
            var file = File.new_for_uri (value);
            valid = (file.query_exists () && Utils.is_valid_image (file));
        }
    }

    public ImageItem (Canvas canvas, Json.Object? save_data = null) {
        base (canvas);
        this.save_data = save_data;

        load_data ();
        style ();
    }

    public ImageItem.from_file (Canvas canvas, File file) {
        base (canvas);
        uri = file.get_uri ();

        style ();
    }

    protected override void load_item_data () {
        this.uri = save_data.get_string_member ("image");
    }

    protected override string serialise_item () {
        return """"type":"image", "image":"%s" """.printf (uri);
    }

    public override void style () {
        if (valid) {
            Utils.set_style (this, IMAGE_STYLE_CSS.printf (uri));
        } else {
            Utils.set_style (this, IMAGE_MISSING_CSS);
        }
    }
}
