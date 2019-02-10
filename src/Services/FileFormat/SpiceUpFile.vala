/*
 *  Copyright (C) 2019 Felipe Escoto <felescoto95@hotmail.com>
 *
 *  This program or library is free software; you can redistribute it
 *  and/or modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General
 *  Public License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301 USA.
 */

public class Spice.Services.SpiceUpFile : Spice.Services.ZipArchiveHandler {
    public File pictures_folder { get; private set; }
    public File thumbnails_folder { get; private set; }

    public File content_file { get; private set; }
    public File styles_file { get; private set; }
    public File version_file { get; private set; }

    public unowned Spice.SlideManager slide_manager {get; construct set; }

    public SpiceUpFile (File _gzipped_file, Spice.SlideManager _slide_manager) {
        Object (opened_file: _gzipped_file.dup (), slide_manager: _slide_manager);
    }

    public void load_file () {
        try {
            open_archive ();
            string content = Services.FileManager.get_presentation_data (content_file);
            slide_manager.load_data (content);
        } catch (Error e) {
            // GZipped file is probably the old format. T
            // Try to use it as content_file as fallback
            debug ("Opening file in legacy mode\n");

            string content = Services.FileManager.get_presentation_data (opened_file);
            slide_manager.load_data (content);
        }
    }

    public void save_file () {
        if (slide_manager.slide_count () == 0) {
            Services.FileManager.delete_file (opened_file);
            clean ();
        } else {
            Services.FileManager.write_file (content_file, slide_manager.serialise ());
            write_to_archive ();
            clean ();
        }
    }

    public override void prepare () {
        base.prepare ();

        var base_path = unarchived_location.get_path ();
        pictures_folder = File.new_for_path (Path.build_filename (base_path, "Pictures"));
        thumbnails_folder = File.new_for_path (Path.build_filename (base_path, "Thumbnails"));

        make_dir (pictures_folder);
        make_dir (thumbnails_folder);

        content_file = File.new_for_path (Path.build_filename (base_path, "content.json"));
        styles_file = File.new_for_path (Path.build_filename (base_path, "styles.json"));
        version_file = File.new_for_path (Path.build_filename (base_path, "version.json"));

        make_file (content_file);
        make_file (styles_file);
        make_file (version_file);
    }
}