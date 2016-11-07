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
    public bool is_fullscreen { public get {
        return is_full_;
    } private set {
        is_full_ = value;
        if (is_full_) {
            aspect_frame.margin = 0;
        } else {
            aspect_frame.margin = 24;
        }
    } default = false;
    }

    private bool is_full_;

    private Spice.Headerbar headerbar;
    private Spice.SlideManager slide_manager;
    private Spice.DynamicToolbar toolbar;

    private Gtk.Revealer sidebar_revealer;
    private Gtk.Revealer toolbar_revealer;
    private Gtk.AspectFrame aspect_frame;

    private Gtk.Stack app_stack;
    private Spice.Welcome welcome;

    private static string ELEMENTARY_STYLESHEET = "
    @define-color colorPrimary #2C2D2E;
    .slide-list {
        background-color: #2A2B2C;
    }

    .new {
        background-color: #363738;
    }

    .slide {
        border-color: black;
        border-radius: 0;
    }

    .canvas {
        box-shadow: inset 0 0 0 2px alpha (#fff, 0.05);
        border-radius: 6px;
    }

    .canvas, frame {
        border-radius: 6px;
    }

    .background {
        background-color: #333435;
    }

    .button.spice {
        color: #DEDEDE;
        background-color: #343536;
        padding: 1px 6px;
    }

    .button.spice:checked {
        background-color: alpha (#000, 0.05);
        background-image: none;
        border-color: alpha (#000, 0.27);
        box-shadow:
            inset 0 0 0 1px alpha (#000, 0.05),
            0 1px 0 0 alpha (@bg_highlight_color, 0.3);
        }

    .inline-toolbar.toolbar {
        background-image: linear-gradient(to bottom, #222324, #292A2B);
    }

    .view.canvas {
        border-width: 1px;
        border-style: outset;
        border-color: rgba(0,0,0,0.75);
    }

    GtkTextView {
        background-color: transparent;
    }

    GtkTextView:selected {
        background-color: black;
	    color: white;
    }
    ";

    public Window (Gtk.Application app) {
        Object (application: app);

        build_ui ();
        connect_signals (app);
        load_settings ();
        show_app ();
        app_stack.set_visible_child_name  ("welcome");
    }

    private void build_ui () {
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
        Granite.Widgets.Utils.set_theming_for_screen (this.get_screen (), ELEMENTARY_STYLESHEET,
                                                      Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        app_stack = new Gtk.Stack ();

        slide_manager = new Spice.SlideManager ();
        headerbar = new Spice.Headerbar (slide_manager);
        headerbar.sensitive = false;

        toolbar = new Spice.DynamicToolbar (slide_manager);

        var slide_list = new Spice.SlideList (slide_manager);
        set_titlebar (headerbar);

        sidebar_revealer = new Gtk.Revealer ();
        toolbar_revealer = new Gtk.Revealer ();

        sidebar_revealer.add (slide_list);
        sidebar_revealer.reveal_child = true;

        toolbar_revealer.add (toolbar);
        toolbar_revealer.reveal_child = true;
        toolbar_revealer.transition_duration = 0;

        aspect_frame = new Gtk.AspectFrame (null, (float ) 0.5, (float ) 0.5, (float ) 1.3, false);
        aspect_frame.get_style_context ().remove_class ("frame");
        aspect_frame.add (slide_manager.slideshow);
        aspect_frame.margin = 24;

        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("app-back");
        grid.attach (toolbar_revealer, 1, 0, 2, 1);
        grid.attach (sidebar_revealer, 0, 0, 1, 2);
        grid.attach (aspect_frame,     1, 1, 1, 1);

        welcome = new Spice.Welcome ();

        app_stack.add_named (grid, "application");
        app_stack.add_named (welcome, "welcome");

        this.add (app_stack);
    }

    private void connect_signals (Gtk.Application app) {
        headerbar.button_clicked.connect ((button) => {
            var item = slide_manager.request_new_item (button);

            if (item != null) {
                toolbar.item_selected (item);
            }
        });

        slide_manager.item_clicked.connect ((item) => {
            toolbar.item_selected (item);
        });

        window_state_event.connect ((e) => {
            if (Gdk.WindowState.FULLSCREEN in e.changed_mask) {
                is_fullscreen = (Gdk.WindowState.FULLSCREEN in e.new_window_state);
                sidebar_revealer.visible = !is_fullscreen;
                sidebar_revealer.reveal_child = !is_fullscreen;
                toolbar_revealer.reveal_child = !is_fullscreen;
            }

            return false;
        });

        welcome.open_file.connect ((file) => {
            Services.FileManager.current_file = file;
            string content = Services.FileManager.open_file ();

            slide_manager.load_data (content);
            headerbar.sensitive = true;
            app_stack.set_visible_child_name  ("application");

            var basename = Services.FileManager.current_file.get_basename ();

            var index_of_last_dot = basename.last_index_of (".");
            var launcher_base = (index_of_last_dot >= 0 ? basename.slice (0, index_of_last_dot) : basename);

            title = launcher_base;
        });
    }

    protected override bool delete_event (Gdk.EventAny event) {
        Services.FileManager.write_file (slide_manager.serialise ());

        int width;
        int height;
        int x;
        int y;

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
        move (settings.pos_x, settings.pos_y);
    }

    public void show_app () {
        show_all ();
        show ();
        present ();
    }
}
