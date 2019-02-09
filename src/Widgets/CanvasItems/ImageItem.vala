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
    public ImageHandler image { get; private set; }

    const string IMAGE_STYLE_CSS = """
        .colored {
            background-color: transparent;
            background-image: url("%s");
            background-position: center;
            background-size: contain;
            background-repeat: no-repeat;
            border: none;
        }
    """;

    const string IMAGE_MISSING_CSS = """
        .colored {
           border: 4px dashed #000000;
           border-color: #c92e34;
        }""";

    public string extension {
        owned get {
            return image.image_extension;
        }
    }

    public string url {
        get {
            return image.url;
        }
    }

    public ImageItem (Canvas? _canvas, Json.Object? _save_data = null) {
        Object (canvas: _canvas, save_data: _save_data);

        load_data ();

        if (canvas != null) style ();
    }

    public ImageItem.from_file (Canvas? _canvas, File file) {
        Object (canvas: _canvas, save_data: null);

        this.image = new ImageHandler.from_file (canvas.window.current_file, file);
        connect_image ();

        if (canvas != null) style ();
    }

    public ImageItem.from_data (Canvas? _canvas, string base64_image, string extension) {
        Object (canvas: _canvas, save_data: null);

        this.image = new ImageHandler.from_data (canvas.window.current_file, extension, base64_image);
        connect_image ();

        if (canvas != null) style ();
    }

    protected override void load_item_data () {
        string? base64_image = null;

        if (save_data.has_member ("image-data")) {
            base64_image = save_data.get_string_member ("image-data");
        }

        if (base64_image != null && base64_image != "") {
            var extension = save_data.get_string_member ("image");
            image = new ImageHandler.from_data (canvas.window.current_file, extension, base64_image);
        } else if (save_data.has_member ("archived-image")) {
            // CURRENT Method of loading
            image = new ImageHandler.from_archived_file (canvas.window.current_file, save_data.get_string_member ("archived-image"));
        } else {
            var tmp_uri = save_data.get_string_member ("image");
            image = new ImageHandler.from_file (canvas.window.current_file, File.new_for_uri (tmp_uri));
        }

        connect_image ();
    }

    protected override string serialise_item () {
        return """"type":"image", %s""".printf (image.serialize ());
    }

    public override void style () {
        if (image.valid) {
            Utils.set_style (this, IMAGE_STYLE_CSS.printf (image.url));
        } else {
            unstyle ();
        }
    }

    private void unstyle () {
         Utils.set_style (this, IMAGE_MISSING_CSS);
    }

    private void connect_image () {
        image.file_changed.connect (() => {
             unstyle ();
             style ();
        });
    }
}
