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

    private static Gee.HashMap<string, File> for_deletion = new Gee.HashMap<string, File> ();

    private unowned Services.SpiceUpFile spice_file;
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

    public ImageHandler.from_data (Services.SpiceUpFile _spice_file, string _extension, string _base64_data) {
        print ("From data\n");
        spice_file = _spice_file;

        var file = spice_file.get_random_file_name (spice_file.pictures_folder, _extension);
        data_to_file (_base64_data, file);

        current_image_file = file;
    }

    public ImageHandler.from_archived_file (Services.SpiceUpFile? _spice_file, string filename) {
        print ("From archive\n");
        spice_file = _spice_file;

        var pictures_folder = spice_file != null ? spice_file.pictures_folder.get_path () : "";
        var path = Path.build_filename (pictures_folder, filename);

        current_image_file = File.new_for_path (path);
    }

    public ImageHandler.from_file (Services.SpiceUpFile _spice_file, File _file) {
        print ("From file\n");
        spice_file = _spice_file;

        replace (_file);
    }

    public void copy_to_another_file () {
        var file = spice_file.get_random_file_name (spice_file.pictures_folder, image_extension);

        current_image_file.copy (file, FileCopyFlags.NONE);
        current_image_file = file;
    }

    public void replace (File file) {
        if (monitor != null) {
            monitor.cancel ();
        }

        if (url != "") {
            current_image_file.delete ();
        }

        var new_file = spice_file.get_random_file_name (spice_file.pictures_folder, get_extension (file.get_basename ()));
        file.copy (new_file, FileCopyFlags.NONE);

        current_image_file = new_file;
    }

    public string serialize () {
        var file = File.new_for_path (url);

        return """"archived-image":"%s" """.printf (file.get_basename ());
    }

    private void monitor_file (File file) {
        try {
            if (monitor != null) {
                monitor.cancel ();
            }

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

    public static void add_for_deletion (ImageHandler image) {
        for_deletion.set (image.current_image_file.get_basename (), image.current_image_file);
    }

    public static void remove_from_deletion (ImageHandler image) {
        for_deletion.unset (image.current_image_file.get_basename ());
    }

    public static void delete_marked_images () {
        foreach (var image in for_deletion.values) {
            image.delete ();
        };

        for_deletion = new Gee.HashMap<string, File> ();
    }
}
