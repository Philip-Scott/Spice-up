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
    const Gtk.TargetEntry[] DRAG_TARGETS = {{ "text/uri-list", 0, 0 }};

    public bool is_fullscreen {
        public get {
            return is_full_;
        } private set {
            is_full_ = value;
            if (value) {
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
    private Gtk.AspectFrame? aspect_frame = null;
    private Gtk.Overlay app_overlay;

    private Gtk.Stack app_stack;
    private Spice.Welcome? welcome = null;

    public Window (Gtk.Application app) {
        Object (application: app);

        build_ui ();

        move (settings.pos_x, settings.pos_y);
        resize (settings.window_width, settings.window_height);
        show_app ();
    }

    private void build_ui () {
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/philip-scott/spice-up/stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        slide_manager = new Spice.SlideManager ();
        app_overlay = new Gtk.Overlay ();
        app_stack = new Gtk.Stack ();
        app_stack.transition_duration = 500;
        app_stack.homogeneous = false;

        app_overlay.add (app_stack);
        this.add (app_overlay);

        GamepadSlideController.startup (slide_manager, this);

        welcome = new Spice.Welcome ();

        welcome.open_file.connect ((file) => {
            open_file (file);
        });

        app_stack.add_named (welcome, "welcome");
    }

    private void show_editor () {
        if (aspect_frame == null) {
            headerbar = new Spice.Headerbar (slide_manager);
            set_titlebar (headerbar);

            toolbar = new Spice.DynamicToolbar (slide_manager);

            slide_list = new Spice.SlideList (slide_manager);

            sidebar_revealer = new Gtk.Revealer ();
            toolbar_revealer = new Gtk.Revealer ();

            sidebar_revealer.add (slide_list);
            sidebar_revealer.reveal_child = true;

            toolbar_revealer.add (toolbar);
            toolbar_revealer.reveal_child = true;
            toolbar_revealer.transition_duration = 0;

            aspect_frame = new Gtk.AspectFrame (null, (float ) 0.5, (float ) 0.5, (float ) 1.7777, false);
            aspect_frame.get_style_context ().add_class ("flat");
            aspect_frame.add (slide_manager.slideshow);
            aspect_frame.margin = 24;

            var grid = new Gtk.Grid ();
            grid.get_style_context ().add_class ("app-back");
            grid.attach (toolbar_revealer, 1, 0, 2, 1);
            grid.attach (sidebar_revealer, 0, 0, 1, 2);
            grid.attach (aspect_frame,     1, 1, 1, 1);

            app_stack.add_named (grid, "application");

            this.show_all ();

            connect_signals (this.application);
        }

        app_stack.set_visible_child_name  ("application");
    }

    public void show_welcome () {
        if (headerbar != null) {
            headerbar.sensitive = false;
        }

        welcome.reload ();
        app_stack.transition_type = Gtk.StackTransitionType.OVER_LEFT_RIGHT;
        app_stack.set_visible_child_name ("welcome");
    }

    private void connect_signals (Gtk.Application app) {
        headerbar.button_clicked.connect ((button) => {
            if (button == Spice.HeaderButton.RETURN) {
                save_current_file ();
                show_welcome ();
                return;
            }

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

        var undo_action = new SimpleAction ("undo-action", null);
        add_action (undo_action);
        app.set_accels_for_action ("win.undo-action", {"<Ctrl>Z"});
        undo_action.activate.connect (() => {
            Spice.Services.HistoryManager.get_instance ().undo ();
        });

        var redo_action = new SimpleAction ("redo-action", null);
        add_action (redo_action);
        app.set_accels_for_action ("win.redo-action", {"<Ctrl><Shift>Z"});
        redo_action.activate.connect (() => {
            Spice.Services.HistoryManager.get_instance ().redo ();
        });

        Gtk.drag_dest_set (aspect_frame, Gtk.DestDefaults.MOTION | Gtk.DestDefaults.DROP, DRAG_TARGETS, Gdk.DragAction.COPY);
        aspect_frame.drag_data_received.connect (on_drag_data_received);

        this.key_press_event.connect (on_key_pressed);
    }

    private void on_drag_data_received (Gdk.DragContext drag_context, int x, int y, Gtk.SelectionData data, uint info, uint time) {
        Gtk.drag_finish (drag_context, true, false, time);

        foreach (var uri in data.get_uris ()) {
            var file = File.new_for_uri (uri);

            if (Utils.is_valid_image (file) && slide_manager.current_slide != null) {
                var item = new ImageItem.from_file (slide_manager.current_slide.canvas, file);
                slide_manager.current_slide.canvas.add_item (item, true);
            }
        }
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
            case 65365: // Page Up
                return previous_slide (true);
            case 65366: // Page Down
                return next_slide (true);
            case 65307: // Esc
                return esc_event ();
        }

        // Ctrl + ? Events
        if (Gdk.ModifierType.CONTROL_MASK in key.state) {
            switch (key.keyval) {
                case 99: // C
                    return copy ();

                case 118: // V
                    return paste ();

                case 120: // X
                    return cut ();

                case 65535: // Delete Key
                case 65288: // Backspace
                    return delete_object ();
            }
        }

        return false;
    }

    private bool cut () {
        copy ();
        delete_object ();
        return true;
    }

    private bool copy () {
        Gtk.Clipboard clipboard = Gtk.Clipboard.get (Gdk.Atom.intern_static_string ("SPICE_UP"));

        var current_item = slide_manager.current_item;

        if (current_item != null) {
            clipboard.set_text (current_item.serialise (), -1);
        } else {
            if (slide_manager.current_slide != null) {
                clipboard.set_text (slide_manager.current_slide.serialise (), -1);
            }
        }

        return true;
    }

    private bool paste () {
        Gtk.Clipboard clipboard = Gtk.Clipboard.get (Gdk.Atom.intern_static_string ("SPICE_UP"));
        var data = clipboard.wait_for_text ();

        if (data == null) return false;

        try {
            var parser = new Json.Parser ();
            parser.load_from_data (data);

            var root_object = parser.get_root ().get_object ();

            if (root_object.has_member ("preview")) {
                slide_manager.new_slide (root_object, true);
            } else {
                slide_manager.current_slide.add_item_from_data (root_object, true, true);
            }
        } catch (Error e) {
            warning ("Cloning didn't work: %s", e.message);
        }

        return true;
    }

    private bool delete_object () {
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

    private bool next_slide (bool override = false) {
        if (is_fullscreen || override) {
            this.slide_manager.next_slide ();
            return true;
        }

        return false;
    }

    private bool previous_slide (bool override = false) {
        if (is_fullscreen || override) {
            this.slide_manager.previous_slide ();
            return true;
        }

        return false;
    }

    private bool esc_event () {
        if (is_fullscreen) {
            this.unfullscreen ();
        } else {
            var slide = slide_manager.current_slide;
            if (slide != null) {
                slide.canvas.unselect_all ();
            }
        }

        return true;
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
        show_editor ();

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
            if (slide_manager.slide_count () == 0) {
                Services.FileManager.delete_file ();
            } else {
                Services.FileManager.write_file (slide_manager.serialise ());
            }

            Services.FileManager.current_file = null;
        }
    }

    protected override bool delete_event (Gdk.EventAny event) {
        Services.FileManager.write_file (slide_manager.serialise ());

        int width, height, x, y;

        get_size (out width, out height);
        get_position (out x, out y);

        settings.pos_x = x;
        settings.pos_y = y;
        settings.window_width = width;
        settings.window_height = height;

        return false;
    }

    public void show_app () {
        show_all ();
        show ();
        present ();
    }
}
