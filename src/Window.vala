/*
* Copyright (c) 2016 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

public class Spice.Window : Gtk.ApplicationWindow {
    private Gtk.Paned pane1;

    public Window (Gtk.Application app) {
        Object (application: app);

        build_ui ();
        connect_signals (app);
        load_settings ();
    }

    private void build_ui () {
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
        
        var headerbar = new Headerbar ();
        
        set_titlebar (headerbar);
        
        this.add (new Spice.Canvas ());
        
        this.show_all ();
    }

    private void connect_signals (Gtk.Application app) {

    }

    protected bool delete_eventop (Gdk.EventAny event) {
        int width;
        int height;
        int x;
        int y;

       // editor.save_file ();
        get_size (out width, out height);
        get_position (out x, out y);

        settings.pos_x = x;
        settings.pos_y = y;
        settings.window_width = width;
        settings.window_height = height;

        return false;
    }

    private void load_settings () {
        resize (settings.window_width, settings.window_height);
        //pane2.position = settings.panel_size;
    }

    private void request_close () {
        close ();
    }

    public void show_app () {
        show ();
        present ();
    }
}
