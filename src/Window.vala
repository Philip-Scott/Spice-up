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

    int old_x;
    int old_y;
    bool? notifications_last_state = null;

    GLib.SettingsSchema? gala_notify_schema = null;
    Settings? gala_notify_settings = null;

    public bool is_presenting {
        public get {
            return is_full_;
        } public set {
            if (value == is_full_) return;

            if (value) {
                // Window Positioning
                var screen = Gdk.Screen.get_default ();
                var monitor_count = screen.get_n_monitors ();
                get_position (out old_x, out old_y);

                fullscreen ();

                if (monitor_count > 1) {
                    presenter_window = new PresenterWindow (slide_manager, this);
                    presenter_window.show ();

                    var primary_monitor = screen.get_primary_monitor ();

                    Gdk.Rectangle rec;
                    screen.get_monitor_geometry (primary_monitor == 1 ? 0 : 1, out rec);

                    move (rec.x, rec.y);
                } else if (DEBUG) {
                    presenter_window = new PresenterWindow (slide_manager, this);
                    presenter_window.show ();
                }

                // set Gala Notifications
                notifications_last_state = get_do_not_disturb_value ();
                set_do_not_disturb_value (true);

                Granite.Staging.Services.Inhibitor.get_instance ().inhibit ("Spice-Up Presentation");
            } else {
                unfullscreen ();
                move (old_x, old_y);

                if (presenter_window != null) {
                    presenter_window.destroy ();
                    presenter_window = null;
                }

                set_do_not_disturb_value (notifications_last_state);
                notifications_last_state = null;

                Granite.Staging.Services.Inhibitor.get_instance ().uninhibit ();
            }

            is_full_ = value;
            aspect_frame.margin = value? 0 : 24;

            sidebar_revealer.visible = !value;
            sidebar_revealer.reveal_child = !value;
            toolbar_revealer.reveal_child = !value;
            headerbar.is_presenting = value;
            presenter_notes.visible =!value;
            slide_manager.checkpoint = null;

            if (toast != null && notification_shown) {
                toast.reveal_child = !value;
            }

            if (slide_manager.current_slide != null) {
                slide_manager.current_slide.canvas.unselect_all ();
            }

            if (!value) {
                slide_manager.end_presentation ();
            }
        }
    }

    private bool notification_shown = false;
    private bool is_full_ = false;

    private Spice.Headerbar headerbar;
    private Spice.SlideManager slide_manager;
    private Spice.SlideList slide_list;
    private Spice.DynamicToolbar toolbar;

    private unowned Granite.Widgets.Toast? toast = null;

    private Gtk.Revealer sidebar_revealer;
    private Gtk.Revealer toolbar_revealer;
    private Gtk.AspectFrame? aspect_frame = null;
    private Gtk.Overlay app_overlay;
    private Spice.PresenterNotes presenter_notes;

    private Gtk.Stack app_stack;
    private Spice.Welcome? welcome = null;
    private PresenterWindow? presenter_window = null;

    public SimpleActionGroup actions { get; private set; }
    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_UNDO = "action_undo";
    public const string ACTION_REDO = "action_redo";
    public const string ACTION_CLONE = "action_clone";

    private const ActionEntry[] action_entries = {
        { ACTION_UNDO, action_undo },
        { ACTION_REDO, action_redo },
        { ACTION_CLONE, action_clone }
    };

    private const string[] editing_actions = {
        ACTION_UNDO,
        ACTION_REDO,
        ACTION_CLONE,
    };

    static construct {
        action_accelerators.set (ACTION_UNDO, "<Control>Z");
        action_accelerators.set (ACTION_REDO, "<Control><Shift>Z");
        action_accelerators.set (ACTION_CLONE, "<Control>D");
    }

    public Window (Gtk.Application app) {
        Object (application: app);

        build_ui ();

        move (settings.pos_x, settings.pos_y);
        resize (settings.window_width, settings.window_height);
        show_app ();

        actions = new SimpleActionGroup ();
        actions.add_action_entries (action_entries, this);
        insert_action_group ("win", actions);

        foreach (var action in action_accelerators.get_keys ()) {
            app.set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
        }
    }

    private void build_ui () {
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/philip-scott/spice-up/stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        slide_manager = new Spice.SlideManager (this);
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

            presenter_notes = new Spice.PresenterNotes ();

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
            grid.attach (toolbar_revealer, 1, 0, 1, 1);
            grid.attach (sidebar_revealer, 0, 0, 1, 3);
            grid.attach (aspect_frame,     1, 1, 1, 1);
            grid.attach (presenter_notes,   1, 2, 1, 1);

            app_stack.add_named (grid, "application");

            this.show_all ();

            connect_signals (this.application);
        }

        app_stack.set_visible_child_name  ("application");

        enable_editing_actions (true);
    }

    public void show_welcome () {
        if (headerbar != null) {
            headerbar.sensitive = false;
        }

        welcome.reload ();
        app_stack.transition_type = Gtk.StackTransitionType.OVER_LEFT_RIGHT;
        app_stack.set_visible_child_name ("welcome");

        enable_editing_actions (false);
    }

    private void connect_signals (Gtk.Application app) {
        headerbar.button_clicked.connect ((button) => {
            if (button == Spice.HeaderButton.RETURN) {
                save_current_file ();
                show_welcome ();
                return;
            }

            if (button == Spice.HeaderButton.NOTES) {
                presenter_notes.reveal_child = !presenter_notes.reveal_child;
                presenter_notes.focus ();
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

        slide_manager.current_slide_changed.connect ((current_slide) => {
            presenter_notes.set_text (current_slide.notes);
        });

        presenter_notes.text_changed.connect ((text) => {
            slide_manager.current_slide.notes = text;
        });

        presenter_notes.notes_area.focus_in_event.connect ((event) => {
            enable_editing_actions (false);
            return false;
        });

        presenter_notes.notes_area.focus_out_event.connect ((event) => {
            enable_editing_actions (true);
            return false;
        });

        Gtk.drag_dest_set (aspect_frame, Gtk.DestDefaults.MOTION | Gtk.DestDefaults.DROP, DRAG_TARGETS, Gdk.DragAction.COPY);
        aspect_frame.drag_data_received.connect (on_drag_data_received);

        //  this.key_press_event.connect (on_key_pressed);
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

    //  private bool on_key_pressed (Gtk.Widget source, Gdk.EventKey key) {
    //      debug ("Key: %s %u", key.str, key.keyval);
    //      if (presenter_notes.notes_focus) return false;

    //      switch (key.keyval) {
    //          // Next Slide
    //          case 65363: // Right Arrow
    //          case 65364: // Down Arrow
    //          case 32:    // Spaceeeeeeee
    //          case 65293: // Enter
    //              return next_slide ();
    //          // Previous Slide
    //          case 65361: // Left Arrow
    //          case 65362: // Up Arrow
    //              return previous_slide ();
    //          case 65365: // Page Up
    //              return previous_slide (true);
    //          case 65366: // Page Down
    //              return next_slide (true);
    //          case 65307: // Esc
    //              return esc_event ();
    //      }

    //      // Ctrl + Shift + ? Events
    //      if (Gdk.ModifierType.CONTROL_MASK in key.state && Gdk.ModifierType.SHIFT_MASK in key.state) {
    //          switch (key.keyval) {
    //              case 80: // P
    //              case 112: // p
    //                  is_presenting = !is_presenting;
    //                  return true;
    //          }
    //      }

    //      // Ctrl + ? Events
    //      if (Gdk.ModifierType.CONTROL_MASK in key.state) {
    //          switch (key.keyval) {
    //              case 67: // C
    //              case 99: // c
    //                  return copy ();

    //              case 86: // V
    //              case 118: // v
    //                  return paste ();

    //              case 88: // X
    //              case 120: // x
    //                  return cut ();

    //              case 65535: // Delete Key
    //              case 65288: // Backspace
    //                  return delete_object ();
    //          }
    //      }

    //      return false;
    //  }


    private bool cut () {
        var current_item = slide_manager.current_item;

        if (current_item != null) {
            Clipboard.cut (slide_manager, current_item);
        } else {
            Clipboard.cut (slide_manager, slide_manager.current_slide);
        }

        return true;
    }

    private bool copy () {
        var current_item = slide_manager.current_item;

        if (current_item != null) {
            Clipboard.copy (slide_manager, current_item);
        } else {
            Clipboard.copy (slide_manager, slide_manager.current_slide);
        }

        return true;
    }

    private bool paste () {
        Clipboard.paste (slide_manager);
        return true;
    }

    private bool delete_object () {
        var current_item = slide_manager.current_item;

        if (current_item != null) {
            Clipboard.delete (current_item);
        } else if (slide_manager.current_slide != null) {
            Clipboard.delete (slide_manager.current_slide);
        }

        return true;
    }

    private bool next_slide (bool override = false) {
        if (is_presenting || override) {
            this.slide_manager.next_slide ();
            return true;
        }

        return false;
    }

    private bool previous_slide (bool override = false) {
        if (is_presenting || override) {
            this.slide_manager.previous_slide ();
            return true;
        }

        return false;
    }

    private bool esc_event () {
        if (is_presenting) {
            is_presenting = false;
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
        Spice.Services.HistoryManager.get_instance ().clear_history ();
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

        set_do_not_disturb_value (notifications_last_state);

        return false;
    }

    public void show_app () {
        show_all ();
        show ();
        present ();
    }

    public bool? get_do_not_disturb_value () {
        if (gala_notify_schema == null) {
            gala_notify_schema = SettingsSchemaSource.get_default ().lookup ("org.pantheon.desktop.gala.notifications", true);
            if (gala_notify_schema == null || !gala_notify_schema.has_key ("do-not-disturb")) {
                gala_notify_schema = null;
                warning ("Notifications will not be disabled");
                return null;
            }
        }

        if (gala_notify_settings == null) {
            gala_notify_settings = new GLib.Settings ("org.pantheon.desktop.gala.notifications");
        }

        return gala_notify_settings.get_boolean ("do-not-disturb");
    }

    public void set_do_not_disturb_value (bool? state) {
        if (state == null || gala_notify_settings == null) return;
        gala_notify_settings.set_boolean ("do-not-disturb", state);
    }

    public void enable_editing_actions (bool enabled) {
        foreach (var action in editing_actions) {
            Utils.set_action_enabled (action, actions, enabled);
        }
    }

    // Actions

    private void action_undo () {
        Spice.Services.HistoryManager.get_instance ().undo ();
    }

    private void action_redo () {
        Spice.Services.HistoryManager.get_instance ().redo ();
    }

    private void action_clone () {
        var current_item = slide_manager.current_item;
        if (current_item != null) {
            Clipboard.duplicate (slide_manager, current_item);
        } else {
            Clipboard.duplicate (slide_manager, slide_manager.current_slide);
        }
    }
}
