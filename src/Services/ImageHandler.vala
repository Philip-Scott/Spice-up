/*
* Copyright (c) 2017 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

public class Spice.ImageHandler : Object {
    public signal void file_changed ();

    const string FILENAME = "/spice-up-%s-img-%u.%s";

    private FileMonitor? monitor = null;
    private bool file_changing = false;

    public bool valid = false;

    public string image_extension {
        owned get {
            return get_extension (url);
        }
    }

    private string url_ = "";
    public string url {
        get {
            return  url_;
        }
    }

    private File current_image_file {
        owned get {
            return File.new_for_path (url);
        } set {
            monitor_file (value);
            valid = (value.query_exists () && Utils.is_valid_image (value));
            url_ = value.get_path ();
            print (url);
            file_changed ();
        }
    }

    private unowned Services.SpiceUpFile spice_file;

    public ImageHandler.from_data (Services.SpiceUpFile _spice_file, string _extension, string _base64_data) {
        print ("From data\n");
        spice_file = _spice_file;

        var file = spice_file.get_random_file_name (spice_file.pictures_folder, _extension);
        data_to_file (_base64_data, file);

        current_image_file = file;
    }

    public ImageHandler.from_archived_file (Services.SpiceUpFile _spice_file, string filename) {
        print ("From archive\n");
        spice_file = _spice_file;

        var path = Path.build_filename (spice_file.pictures_folder.get_path (), filename);
        current_image_file = File.new_for_path (path);
    }

    public ImageHandler.from_file (Services.SpiceUpFile _spice_file, File _file) {
        print ("From file\n");
        spice_file = _spice_file;

        var file = spice_file.get_random_file_name (spice_file.pictures_folder, get_extension (_file.get_basename ()));
        replace (_file);

        current_image_file = file;
    }

    public void replace (File file) {
        // TODO: Implement copy from outside file to this
        if (monitor != null) {
            monitor.cancel ();
        }

        //  image_extension = get_extension (file.get_basename ());
        //  data_from_file (file);
        //  url = data_to_file (base64_image);
    }

    public string serialize () {
        var file = File.new_for_path (url);

        return """"archived-image":"%s" """.printf (file.get_basename ());
    }

    private void monitor_file (File file) {
        try {
            monitor = file.monitor (FileMonitorFlags.NONE, null);

            monitor.changed.connect ((src, dest, event) => {
                if (event == FileMonitorEvent.CHANGED) {
                    file_changing = true;
                } else if (event == FileMonitorEvent.CHANGES_DONE_HINT && file_changing) {
                    file_changed ();
                    file_changing = false;
                }
            });
        } catch (Error e) {
            warning ("Could not monitor file: %s", e.message);
        }
    }

    private string get_extension (string filename) {
        var parts = filename.split (".");
        if (parts.length > 1) {
            return parts[parts.length - 1];
        } else {
            return "png";
        }
    }

    private void data_to_file (string data, File file) {
        Spice.Services.FileManager.base64_to_file (file.get_path (), data);
    }
}
