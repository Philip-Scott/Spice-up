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
    Test.add_func ("/ColorItem/InitialVersion", () => {
        var item = load_test ("""{ "type": "color", "background_color": "blue" } """);

        assert (item.border_radius == 0);
        item.border_radius = 8;

        saving_test (item);
    });

    Test.add_func ("/ColorItem/V2", () => {
        var item = load_test ("""{ "type": "color", "background_color": "blue", "border-radius": 8 } """);

        assert (item.border_radius == 8);

        saving_test (item);
    });
}

Spice.ColorItem load_test (string raw) {
    var json = Spice.Utils.get_json (raw);
    var item = new Spice.ColorItem (new Spice.Canvas (), json);

    assert (item.background_color == "blue");

    return item;
}

void saving_test (Spice.ColorItem item) {
    var json = Spice.Utils.get_json (item.serialise ());

    assert (json.get_string_member ("type") == "color");
    assert (json.get_string_member ("background_color") == "blue");
    assert (json.get_int_member ("border-radius") == 8);
}


int main (string[] args) {
    Gtk.init (ref args);
    Test.init (ref args);

    add_tests ();
    return Test.run ();
}
