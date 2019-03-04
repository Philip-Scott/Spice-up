/*
* Copyright (c) 2011-2016 Felipe Escoto (https://github.com/Philip-Scott/Notes-up)
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

public class Spice.Services.Settings : Granite.Services.Settings {
    private static Settings? instance = null;

    public int pos_x { get; set; }
    public int pos_y { get; set; }
    public int window_width { get; set; }
    public int window_height { get; set; }
    public string last_fetch { get; set; }
    public string[] last_files { get; set; }
    public string controler_config { get; set; }

    public static Settings get_instance () {
        if (instance == null) {
            instance = new Settings ();
        }

        return instance;
    }

    private Settings () {
        base ("com.github.philip-scott.spice-up");
    }

    public void add_file (string file) {
        if (Granite.Services.System.history_is_enabled ()) return;

        var current_files = last_files;

        Gee.List<string> existing_files = new Gee.ArrayList<string> ();
        existing_files.add_all_array (current_files);

        if (file in current_files) {
            existing_files.remove (file);
        }

        existing_files.insert (0, file);
        if (existing_files.size > 50) {
            existing_files = existing_files.slice (0, 10);
        }

        last_files = existing_files.to_array ();
    }
}
