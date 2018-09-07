/*
* Copyright (c) 2018 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

public class Spice.Services.Fetcher {
    private const string TEMPLATES_URL = "https://spice-up-dev.azurewebsites.net/api/get-templates";
    private const int64 CACHE_LIFE = 43200; // 1/2 a day
    public const int CURRENT_VERSION = 1;

    private File cache_file;
    private string cache = "";
    private Mutex mutex = Mutex ();

    public Fetcher () {
        cache_file = File.new_for_path (Environment.get_tmp_dir () + "/com.github.philip-scott.spice-up.cache.json");
    }

    public void fetch () {
        var now = new DateTime.now_utc ().to_unix ();

        var settigns = Spice.Services.Settings.get_instance ();
        var previous_fetch = int64.parse (settigns.last_fetch);

        var try_to_fetch = now - previous_fetch > CACHE_LIFE || !cache_file.query_exists ();

        if (try_to_fetch) {
            debug ("Getting templates from server\n");
            new Thread<void*> ("fetch-templates", () => {
                var session = new Soup.Session ();
                var message = new Soup.Message ("GET", TEMPLATES_URL);

                session.send_message (message);

                var data = new StringBuilder ();
                foreach (var c in message.response_body.data) {
                    data.append ("%c".printf (c));
                }

                mutex.lock ();

                cache = data.str;
                if (cache != "") {
                    save_to_cache (cache);
                    settigns.last_fetch = now.to_string ();
                }

                mutex.unlock ();

                return null;
            });
        } else {
            debug ("Getting templates from cache\n");
        }
    }

    public string get_data () {
        mutex.lock ();
        if (cache == "" && cache_file.query_exists ()) {
            cache = Services.FileManager.get_data (cache_file);
        }

        string data = cache;
        mutex.unlock ();

        return data;
    }

    private void save_to_cache (string data) {
        try {
            GLib.FileUtils.set_data (cache_file.get_path (), data.data);
        } catch (Error e) {
            warning ("Could not write cache to temp file \"%s\": %s", cache_file.get_basename (), e.message);
        }
    }
}