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
    Test.add_func ("/Canvas/initial", () => {
        var item =
        load_test ("""{"background-color":"blue", "background-pattern":"pattern" } """);

        item.background_color = "red";
        item.background_pattern = "pattern2";
        saving_test (item);
    });
}

Spice.Canvas load_test (string raw) {
    var json = Spice.Utils.get_json (raw);
    var item = new Spice.Canvas (Spice.Application.get_active_spice_window (), json);

    assert (item.background_color == "blue");
    assert (item.background_pattern == "pattern");

    return item;
}

void saving_test (Spice.Canvas item) {
    var json = Spice.Utils.get_json ("{%s}".printf (item.serialise ()));

    assert (json.get_string_member ("background-color") == "red");
    assert (json.get_string_member ("background-pattern") == "pattern2");
}

int main (string[] args) {
    Gtk.init (ref args);
    Test.init (ref args);

    add_tests ();
    return Test.run ();
}
