/*
* Copyright (c) 2017 Felipe Escoto
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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

void add_tests () {
    Test.add_func ("/ImageItem/InitialVersion", () => {
        var item = load_test ("""{ "type":"image", "image":"file:///home/test/OldImage.jpg" } """);
        saving_test (item);

        Spice.ImageHandler.cleanup ();
    });

    Test.add_func ("/ImageItem/V2", () => {
        var item = load_test ("""{ "type":"image", "image":"jpg", "image-data":"Base64Data:/home/test/OldImage.jpg" } """);
        saving_test (item);

        Spice.ImageHandler.cleanup ();
    });
}

Spice.ImageItem load_test (string raw) {
    var json = Spice.Utils.get_json (raw);
    var item = new Spice.ImageItem (new Spice.Canvas (), json);

    assert ("Base64Data:/home/test/OldImage.jpg" == Spice.ImageHandler.base64_image);

    return item;
}

void saving_test (Spice.ImageItem item) {
    var json = Spice.Utils.get_json (item.serialise ());

    assert (json.get_string_member ("type") == "image");
    assert (json.get_string_member ("image") == "jpg");
    assert (json.get_string_member ("image-data") == "Base64Data:/home/test/OldImage.jpg");
}

int main (string[] args) {
    Gtk.init (ref args);
    Test.init (ref args);

    add_tests ();
    return Test.run ();
}

public class Spice.ImageHandler : Object {
    const string FILENAME = "/spice-up-%s-img-%u.%s";

    public signal void file_changed ();

    public bool valid = false;
    public static string? base64_image = null;

    public string image_extension { get; private set; }

    private string url_ = "";
    public string url {
        get {
            return url_;
        } set {
            url_ = value;
            file_changed ();
        }
    }

    public static void cleanup () {
        base64_image = null;
    }

    public ImageHandler.from_data (string _extension, string _base64_data) {
        image_extension = _extension != "" ? _extension : "png";
        base64_image = _base64_data;
        url = data_to_file (_base64_data);
    }

    public ImageHandler.from_file (File file) {
        image_extension = get_extension (file.get_basename ());
        data_from_filename (file.get_path ());
        url = data_to_file (base64_image);
    }

    public string serialize () {
        return """"image":"%s", "image-data":"%s" """.printf (image_extension, base64_image);
    }

    private string get_extension (string filename) {
        return "jpg";
    }

    private void data_from_filename (string path) {
        base64_image = "Base64Data:" + path;
    }

    private string data_to_file (string data) {
        return "data.file";
    }
}
