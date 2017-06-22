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
    private static uint file_id = 0;
    const string FILENAME = "/spice-up-%s-img-%u";

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

    private string? base64_image = null;

    private bool valid = false;

    private string url_ = "";
    public string url {
        get {
            return url_;
        } set {
            url_ = value;
            var file = File.new_for_path (value);
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

        data_from_filename (file.get_path ());

        style ();
    }

    protected override void load_item_data () {
        if (save_data.has_member ("image-data")) {
            base64_image = save_data.get_string_member ("image-data");
        }

        if (base64_image != null && base64_image != "") {
            stderr.printf ("Loading uri data\n");
            this.url = data_to_file (base64_image);
        } else {
            var tmp_uri = save_data.get_string_member ("image");
            data_from_filename (File.new_for_uri (tmp_uri).get_path ());
        }
    }

    protected override string serialise_item () {
        return """"type":"image", "image":"", "image-data":"%s" """.printf (base64_image);
    }

    public override void style () {
        if (valid) {
            Utils.set_style (this, IMAGE_STYLE_CSS.printf (url));
        } else {
            Utils.set_style (this, IMAGE_MISSING_CSS);
        }
    }

    private void data_from_filename (string path) {
        base64_image = Spice.Services.FileManager.file_to_base64 (path);
        this.url = data_to_file (base64_image);
    }

    private string data_to_file (string data) {
        var filename = Environment.get_tmp_dir () + FILENAME.printf (Environment.get_user_name (), file_id++);
        Spice.Services.FileManager.base64_to_file (filename, data);

        return filename;
    }
}
