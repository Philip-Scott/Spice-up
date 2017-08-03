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
    Test.add_func ("/TextItem/initial", () => {
        var item = 
        load_test ("""{"type":"text",
                       "text": "The Title",
                       "font": "raleway",
                       "color": "#fff",
                       "font-size": 50 }
                   """);
        saving_test (item);
    });

    Test.add_func ("/TextItem/With-FontStyle", () => {
        var item = 
        load_test ("""{"type":"text",
                       "text": "The Title",
                       "font": "raleway",
                       "color": "#fff",
                       "font-size": 50,
                       "font-style":"Regular"}
                    """);
        saving_test (item);
    });

    Test.add_func ("/TextItem/WithJustification", () => {
        var item = 
        load_test ("""{"type":"text",
                       "text": "The Title",
                       "font": "raleway",
                       "color": "#fff",
                       "font-size": 50,
                       "font-style":"Regular",
                       "justification": 1 }
                    """);
        saving_test (item);
    });

    Test.add_func ("/TextItem/WithBase64Text", () => {
        var item = 
        load_test ("""{"type":"text",
                       "text": "",
                       "text-data" : "VGhlIFRpdGxl",
                       "font": "raleway",
                       "color": "#fff",
                       "font-size": 50,
                       "font-style":"Regular",
                       "justification": 1 }
                   """);
        saving_test (item);
    });
}

Spice.TextItem load_test (string raw) {
    var json = Spice.Utils.get_json (raw);
    var color_item = new Spice.TextItem (new Spice.Canvas (), json);

    assert (color_item.text == "The Title");
    assert (color_item.font_color == "#fff");
    assert (color_item.font_size == 50);
    assert (color_item.font_style == "Regular");
    assert (color_item.justification == 1);

    return color_item;
}

void saving_test (Spice.TextItem item) {
    var json = Spice.Utils.get_json (item.serialise ());
    assert (json.get_string_member ("text") == "");
    assert (json.get_string_member ("text-data") == "VGhlIFRpdGxl");
    assert (json.get_string_member ("font") == "raleway");
    assert (json.get_string_member ("color") == "#fff");
    assert (json.get_int_member ("font-size") == 50);
    assert (json.get_string_member ("font-style") == "Regular");
    assert (json.get_int_member ("justification") == 1);
}

int main (string[] args) {
    Gtk.init (ref args);
    Test.init (ref args);

    add_tests ();
    return Test.run ();
}
