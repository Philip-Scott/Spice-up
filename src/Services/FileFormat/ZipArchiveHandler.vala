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

public class Spice.Services.ZipArchiveHandler {

    // Prefix to be added at the beginning of the folder name when a gzipped file is opened. Should start with a period to hide the folder by default
    private const string UNARCHIVED_PREFIX = ".~lock.spiceup.";

    /**
     * The GZipped File that opened this archive
     */
    public File opened_file { get; private set; }

    /**
     * The Unzipped folder location
     */
    public File unarchived_location { get; private set; }

    /**
     * Creates a zipped file for archive purposes
     */
    public ZipArchiveHandler (File gzipped_file) {
        opened_file = gzipped_file.dup ();

        var parent_folder = opened_file.get_parent ().get_path ();
        unarchived_location = File.new_for_path (Path.build_filename (parent_folder, UNARCHIVED_PREFIX + opened_file.get_basename ()));
    }

    protected void make_dir (File file) {
        if (!file.query_exists ()) {
            file.make_directory_with_parents ();
        }
    }

    protected void make_file (File file) {
        if (!file.query_exists ()) {
            file.create (FileCreateFlags.REPLACE_DESTINATION);
        }
    }

    /**
     * Used to create all the files needed for this if they do not exist.
     *
     * Should be overwritten to add your own files and folders for the internal
     * file structure you require. Make sure to call base.prepare ()
     */
    public virtual void prepare () {
        try {
            var parent_folder = opened_file.get_parent ();
            make_dir (parent_folder);
            make_file (opened_file);
            make_dir (unarchived_location);
        } catch (Error e) {
            error ("Could not write file: %s", e.message);
        }
    }

    /**
     * Used to check if the file was already extracted. Use this to handle recovery for your users.
     */
    public virtual bool is_opened () {
        return unarchived_location.query_exists ();
    }

    /**
     * Extracts the contents of the file to unarchived_location
     */
    public void open () throws Error {
        extract (opened_file, unarchived_location);
    }

    /**
     * Saves content from the unzipped location to the GZipped file.
     */
    public void write_to_archive () throws Error {
        // Saving to a temp file first to avoid dataloss on a crash

        var tmp_file = File.new_for_path (opened_file.get_path () + ".tmp");

        compress (unarchived_location, tmp_file);
        if (opened_file.query_exists ()) {
            opened_file.delete ();
        }

        FileUtils.rename (tmp_file.get_path (), opened_file.get_path ());
    }

    /**
     * Removes all files from the unarchived location. Should run before closing the program to cleanup temp files
     */
    public void clean () throws Error {
        // Checking if it contains the prefix as a safety to prevent errors
        // This function is dangerous. not using the constant here to prevent erors
        if (is_opened () && unarchived_location.get_path ().contains (".~lock.spice-up.")) {
            delete_recursive (unarchived_location);
            unarchived_location.delete ();
        }
    }

    // DANGEROUS
    private void delete_recursive (File file) {
        try {
            var enumerator = file.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                var current_file = file.resolve_relative_path (file_info.get_name ());

                if (file_info.get_file_type () == FileType.DIRECTORY) {
                    delete_recursive (current_file);
                }

                current_file.delete ();
            }
        } catch (Error e) {
            critical ("Error: %s\n", e.message);
        }
    }

    // Extracts all contents of the gzip file to the location
    private static void extract (File gzipped_file, File location) throws Error {
        Archive.ExtractFlags flags;
        flags = Archive.ExtractFlags.TIME;
        flags |= Archive.ExtractFlags.PERM;
        flags |= Archive.ExtractFlags.ACL;
        flags |= Archive.ExtractFlags.FFLAGS;

        Archive.Read archive = new Archive.Read ();
        archive.support_format_all ();
        archive.support_filter_all ();

        Archive.WriteDisk extractor = new Archive.WriteDisk ();
        extractor.set_options (flags);
        extractor.set_standard_lookup ();

        if (archive.open_filename (gzipped_file.get_path (), 10240) != Archive.Result.OK) {
            throw new FileError.FAILED ("Error opening %s: %s (%d)", gzipped_file.get_path (), archive.error_string (), archive.errno ());
            return;
        }

        unowned Archive.Entry entry;
        Archive.Result last_result;
        while ((last_result = archive.next_header (out entry)) == Archive.Result.OK) {
            entry.set_pathname (Path.build_filename (location.get_path (), entry.pathname ()));

            if (extractor.write_header (entry) != Archive.Result.OK) {
                continue;
            }

            void* buffer = null;
            size_t buffer_length;
            Posix.off_t offset;
            while (archive.read_data_block (out buffer, out buffer_length, out offset) == Archive.Result.OK) {
                if (extractor.write_data_block (buffer, buffer_length, offset) != Archive.Result.OK) {
                    break;
                }
            }
        }

        if (last_result != Archive.Result.EOF) {
            critical ("Error: %s (%d)", archive.error_string (), archive.errno ());
        }
    }

    // Compresses all files recursibly from location to the gzipped file.
    private static void compress (File location, File gzipped_file) throws Error {
        var to_write = File.new_for_path (gzipped_file.get_path ());
        if (to_write.query_exists ()) {
            to_write.delete ();
        }

        to_write.create (FileCreateFlags.REPLACE_DESTINATION);

        Archive.Write archive = new Archive.Write ();
        archive.set_format_zip ();
        archive.open_filename (to_write.get_path ());

        add_to_archive_recursive (location, location, archive);

        if (archive.close () != Archive.Result.OK) {
            critical ("Error : %s (%d)", archive.error_string (), archive.errno ());
        }
    }

    private static void add_to_archive_recursive (File initial_folder, File folder, Archive.Write archive) {
        try {
            var enumerator = folder.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo current_info;
            while ((current_info = enumerator.next_file ()) != null) {
                var current_file = folder.resolve_relative_path (current_info.get_name ());

                if (current_info.get_file_type () == FileType.DIRECTORY) {
                    add_to_archive_recursive (initial_folder, current_file, archive);
                } else {
                    GLib.FileInfo file_info = current_file.query_info (GLib.FileAttribute.STANDARD_SIZE, GLib.FileQueryInfoFlags.NONE);

                    FileInputStream input_stream = current_file.read ();
                    DataInputStream data_input_stream = new DataInputStream (input_stream);

                    // Add an entry to the archive
                    Archive.Entry entry = new Archive.Entry ();
                    entry.set_pathname (initial_folder.get_relative_path (current_file));
                    entry.set_size (file_info.get_size ());
                    entry.set_filetype ((uint) Posix.S_IFREG);
                    entry.set_perm (0644);

                    if (archive.write_header (entry) != Archive.Result.OK) {
                        critical ("Error writing '%s': %s (%d)", current_file.get_path (), archive.error_string (), archive.errno ());
                        return;
                    }

                    // Add the actual content of the file
                    size_t bytes_read;
                    uint8[64] buffer = new uint8[64];
                    while (data_input_stream.read_all (buffer, out bytes_read)) {
                        if (bytes_read <= 0) {
                            break;
                        }

                        archive.write_data (buffer, bytes_read);
                    }
                }
            }
        } catch (Error e) {
            critical ("Error: %s\n", e.message);
        }
    }
}