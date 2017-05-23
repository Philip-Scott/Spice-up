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

    private bool notification_shown = false;
    private bool is_full_;

    private Spice.Headerbar headerbar;
    private Spice.SlideManager slide_manager;
    private Spice.SlideList slide_list;
    private Spice.DynamicToolbar toolbar;

    private unowned Granite.Widgets.Toast? toast = null;

    private Gtk.Revealer sidebar_revealer;
    private Gtk.Revealer toolbar_revealer;
    private Gtk.AspectFrame aspect_frame;
    private Gtk.Overlay app_overlay;

    private Gtk.Stack app_stack;
    private Spice.Welcome welcome;

    private static string ELEMENTARY_STYLESHEET = "
    @define-color colorPrimary #2C2D2E;
    .slide-list {
        background-color: #2A2B2C;
        border-right: solid 1px rgba(0,0,0,0.75)
    }

    .slide-list .list-row:selected {
        box-shadow: inset 0px 24px 10px -6px rgba(0,0,0, 0.53);
        background-color: #222324;
    }

    .new.slide {
        background-color: #363738;
        border-radius: 4px;
        border-color: black;
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
        border-style: solid;
        border-color: rgba(0,0,0,0.75);
    }

    .view.canvas.preview {
        border-color: black;
        border-radius: 4px;
    }

    GtkTextView {
        background-color: transparent;
    }

    GtkTextView:selected {
        background-color: rgba(0,0,0,0.75);
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
        app_overlay = new Gtk.Overlay ();
        app_stack = new Gtk.Stack ();

        slide_manager = new Spice.SlideManager ();
        headerbar = new Spice.Headerbar (slide_manager);
        headerbar.sensitive = false;

        toolbar = new Spice.DynamicToolbar (slide_manager);

        slide_list = new Spice.SlideList (slide_manager);
        set_titlebar (headerbar);

        sidebar_revealer = new Gtk.Revealer ();
        toolbar_revealer = new Gtk.Revealer ();

        sidebar_revealer.add (slide_list);
        sidebar_revealer.reveal_child = true;

        toolbar_revealer.add (toolbar);
        toolbar_revealer.reveal_child = true;
        toolbar_revealer.transition_duration = 0;

        aspect_frame = new Gtk.AspectFrame (null, (float ) 0.5, (float ) 0.5, (float ) 1.7777, false);
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

        app_overlay.add (app_stack);
        this.add (app_overlay);

        GamepadSlideController.startup (slide_manager, this);
    }

    private void connect_signals (Gtk.Application app) {
        headerbar.button_clicked.connect ((button) => {
            var item = slide_manager.request_new_item (button);

            if (item != null) {
                toolbar.item_selected (item, true);
            }
        });

        slide_manager.item_clicked.connect ((item) => {
            toolbar.item_selected (item);
        });

        slide_manager.aspect_ratio_changed.connect ((new_ratio) => {
            SlideList.WIDTH = Spice.AspectRatio.get_width_value (new_ratio);
            aspect_frame.ratio = Spice.AspectRatio.get_ratio_value (new_ratio);
        });

        window_state_event.connect ((e) => {
            if (Gdk.WindowState.FULLSCREEN in e.changed_mask) {
                is_fullscreen = (Gdk.WindowState.FULLSCREEN in e.new_window_state);
                sidebar_revealer.visible = !is_fullscreen;
                sidebar_revealer.reveal_child = !is_fullscreen;
                toolbar_revealer.reveal_child = !is_fullscreen;
                slide_manager.checkpoint = null;

                if (toast != null && notification_shown) {
                    toast.reveal_child = !is_fullscreen;
                }

                if (slide_manager.current_slide != null) {
                    slide_manager.current_slide.canvas.unselect_all ();
                }
            }

            return false;
        });

        welcome.open_file.connect ((file) => {
            open_file (file);
        });

        this.key_press_event.connect (on_key_pressed);
    }

    private bool on_key_pressed (Gtk.Widget source, Gdk.EventKey key) {
        debug ("Key: %s %u", key.str, key.keyval);

        switch (key.keyval) {
            // Next Slide
            case 65363: // Right Arrow
            case 65364: // Down Arrow
            case 32:    // Spaceeeeeeee
            case 65293: // Enter
                return next_slide ();
            // Previous Slide
            case 65361: // Left Arrow
            case 65362: // Up Arrow
                return previous_slide ();

            case 65535: // Delete Key
            case 65288: // Backspace
                return delete_object (key);
        }

        return false;
    }

    private bool delete_object (Gdk.EventKey key) {
        if ((key.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
            var current_item = slide_manager.current_item;

            if (current_item != null) {
                current_item.delete ();
            } else {
                if (slide_manager.current_slide != null) {
                    slide_manager.current_slide.delete ();
                }
            }
            return true;
        }

        return false;
    }

    private bool next_slide () {
        if (is_fullscreen) {
            this.slide_manager.next_slide ();
            return true;
        }

        return false;
    }

    private bool previous_slide () {
        if (is_fullscreen) {
            this.slide_manager.previous_slide ();
            return true;
        }

        return false;
    }

    public void add_toast_notification (Granite.Widgets.Toast toast) {
        if (toast != this.toast) {
            this.toast = toast;
            toast.closed.connect (() => {
                notification_shown = false;
            });

            toast.default_action.connect (() => {
                notification_shown = false;
            });

            app_overlay.add_overlay (toast);
            app_overlay.show_all ();
        }

        notification_shown = true;
        toast.send_notification ();
    }

    public void open_file (File file) {
        save_current_file ();

        slide_manager.reset ();
        Services.FileManager.current_file = file;
        string content = Services.FileManager.open_file ();

        slide_manager.load_data (content);
        headerbar.sensitive = true;
        app_stack.set_visible_child_name  ("application");

        var basename = Services.FileManager.current_file.get_basename ();

        var index_of_last_dot = basename.last_index_of (".");
        var launcher_base = (index_of_last_dot >= 0 ? basename.slice (0, index_of_last_dot) : basename);

        title = launcher_base;
    }

    public void save_current_file () {
        if (Services.FileManager.current_file != null) {
            Services.FileManager.write_file (slide_manager.serialise ());
        }
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
