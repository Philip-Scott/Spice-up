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
                enable_action_group (editing_actions, false);
                enable_action_group (presenting_actions, true);

                motion_notify_event.connect (request_to_hide_mouse);
                request_to_hide_mouse ();
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
                enable_action_group (editing_actions, true);
                enable_action_group (presenting_actions, false);
                motion_notify_event.disconnect (request_to_hide_mouse);
                hide_cursor (false);
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

    public Spice.Services.HistoryManager history_manager { get; construct; }
    public File? current_file { get; private set; default = null; }

    public SimpleActionGroup actions { get; private set; }
    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_UNDO = "action_undo";
    public const string ACTION_REDO = "action_redo";
    public const string ACTION_CLONE = "action_clone";
    public const string ACTION_PRESENT_START = "action_present_start";
    public const string ACTION_PRESENT_STOP = "action_present_stop";
    public const string ACTION_SHOW_WELCOME = "show_welcome";
    public const string ACTION_NOTES = "toggle_notes";
    public const string ACTION_EXPORT = "action_export";
    public const string ACTION_NEW_SLIDE = "action_new_slide";
    public const string ACTION_INSERT_TEXT = "action_insert_txt";
    public const string ACTION_INSERT_IMG = "action_insert_img";
    public const string ACTION_INSERT_SHAPE = "action_insert_shape";
    public const string ACTION_BRING_FWD = "action_bring_fwd";
    public const string ACTION_BRING_BWD = "action_send_bwd";
    public const string ACTION_COPY = "action_copy";
    public const string ACTION_CUT = "action_cut";
    public const string ACTION_PASTE = "action_paste";
    public const string ACTION_DELETE = "action_delete";

    public const string ACTION_NEXT = "action_next";
    public const string ACTION_PREVIOUS = "action_previous";
    public const string ACTION_NEXT_EDIT = "action_next_editing";
    public const string ACTION_PREVIOUS_EDIT = "action_previous_editing";


    private const ActionEntry[] action_entries = {
        { ACTION_UNDO, action_undo },
        { ACTION_REDO, action_redo },
        { ACTION_CLONE, action_clone },
        { ACTION_PRESENT_START, action_present_toggle },
        { ACTION_PRESENT_STOP, action_present_toggle },
        { ACTION_SHOW_WELCOME, show_welcome },
        { ACTION_NOTES, action_toggle_notes },
        { ACTION_EXPORT, action_export },
        { ACTION_NEW_SLIDE, action_new_slide },
        { ACTION_INSERT_TEXT, action_insert_txt },
        { ACTION_INSERT_IMG, action_insert_img },
        { ACTION_INSERT_SHAPE, action_insert_shape },
        { ACTION_BRING_FWD, action_bring_fwd },
        { ACTION_BRING_BWD, action_send_bwd },
        { ACTION_COPY, copy },
        { ACTION_CUT, cut },
        { ACTION_PASTE, paste },
        { ACTION_DELETE, delete_object},
        { ACTION_NEXT, next_slide },
        { ACTION_PREVIOUS, previous_slide },
        { ACTION_NEXT_EDIT, next_slide },
        { ACTION_PREVIOUS_EDIT, previous_slide }
    };

    private const string[] editing_actions = {
        ACTION_UNDO,
        ACTION_REDO,
        ACTION_CLONE,
        ACTION_PRESENT_START,
        ACTION_SHOW_WELCOME,
        ACTION_NOTES,
        ACTION_EXPORT,
        ACTION_NEW_SLIDE,
        ACTION_INSERT_TEXT,
        ACTION_INSERT_IMG,
        ACTION_INSERT_SHAPE,
        ACTION_BRING_FWD,
        ACTION_BRING_BWD,
        ACTION_COPY,
        ACTION_CUT,
        ACTION_PASTE,
        ACTION_DELETE,
        ACTION_NEXT_EDIT,
        ACTION_PREVIOUS_EDIT
    };

    private const string[] presenting_actions = {
        ACTION_PRESENT_STOP,
        ACTION_NEXT,
        ACTION_PREVIOUS
    };

    static construct {
        action_accelerators.set (ACTION_UNDO, "<Control>Z");
        action_accelerators.set (ACTION_REDO, "<Control><Shift>Z");
        action_accelerators.set (ACTION_CLONE, "<Control>D");
        action_accelerators.set (ACTION_PRESENT_START, "<Control><Alt>P");
        action_accelerators.set (ACTION_PRESENT_STOP, "Escape");
        action_accelerators.set (ACTION_PRESENT_STOP, "<Control><Alt>P");
        action_accelerators.set (ACTION_SHOW_WELCOME, "<Control>W");
        action_accelerators.set (ACTION_NOTES, "<Control>P");
        action_accelerators.set (ACTION_EXPORT, "<Control><Shift>E");
        action_accelerators.set (ACTION_NEW_SLIDE, "<Control><Shift>N");
        action_accelerators.set (ACTION_INSERT_TEXT, "<Control><Shift>T");
        action_accelerators.set (ACTION_INSERT_IMG, "<Control><Shift>Y");
        action_accelerators.set (ACTION_INSERT_SHAPE, "<Control><Shift>U");

        action_accelerators.set (ACTION_COPY, "<Control>C");
        action_accelerators.set (ACTION_CUT, "<Control>X");
        action_accelerators.set (ACTION_PASTE, "<Control>V");
        action_accelerators.set (ACTION_DELETE, "<Control>Delete");
        action_accelerators.set (ACTION_DELETE, "<Control>BackSpace");
        action_accelerators.set (ACTION_NEXT, "Right");
        action_accelerators.set (ACTION_NEXT, "Down");
        action_accelerators.set (ACTION_NEXT, "space");
        action_accelerators.set (ACTION_NEXT, "Return");
        action_accelerators.set (ACTION_PREVIOUS, "Left");
        action_accelerators.set (ACTION_PREVIOUS, "Up");
        action_accelerators.set (ACTION_NEXT_EDIT, "Page_Down");
        action_accelerators.set (ACTION_PREVIOUS_EDIT, "Page_Up");

        action_accelerators.set (ACTION_BRING_FWD, "<Control><Alt>Page_Up");
        action_accelerators.set (ACTION_BRING_BWD, "<Control><Alt>Page_Down");
    }

    public Window (Gtk.Application app) {
        Object (application: app);

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

    construct {
        history_manager = new Spice.Services.HistoryManager ();

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

        enable_action_group (editing_actions, true);
        enable_action_group (presenting_actions, false);
    }

    public void show_welcome () {
        save_current_file ();

        if (headerbar != null) {
            headerbar.sensitive = false;
        }

        welcome.reload ();
        app_stack.transition_type = Gtk.StackTransitionType.OVER_LEFT_RIGHT;
        app_stack.set_visible_child_name ("welcome");

        enable_action_group (editing_actions, false);
        enable_action_group (presenting_actions, false);

        if (current_file != null) {
            Spice.Application.instance.unregister_file_from_window (current_file);
            current_file = null;
        }
    }

    private void connect_signals (Gtk.Application app) {
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

        Gtk.drag_dest_set (aspect_frame, Gtk.DestDefaults.MOTION | Gtk.DestDefaults.DROP, DRAG_TARGETS, Gdk.DragAction.COPY);
        aspect_frame.drag_data_received.connect (on_drag_data_received);
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

    private void cut () {
        var current_item = slide_manager.current_item;

        if (current_item != null) {
            Clipboard.cut (slide_manager, current_item);
        } else {
            Clipboard.cut (slide_manager, slide_manager.current_slide);
        }

    }

    private void copy () {
        var current_item = slide_manager.current_item;

        if (current_item != null) {
            Clipboard.copy (slide_manager, current_item);
        } else {
            Clipboard.copy (slide_manager, slide_manager.current_slide);
        }
    }

    private void paste () {
        Clipboard.paste (slide_manager);
    }

    public void delete_object () {
        var current_item = slide_manager.current_item;

        if (current_item != null) {
            Clipboard.delete (current_item);
            slide_manager.current_slide.canvas.unselect_all ();
        } else if (slide_manager.current_slide != null) {
            Clipboard.delete (slide_manager.current_slide);
        }
    }

    private void next_slide () {
        this.slide_manager.next_slide ();
    }

    private void previous_slide  () {
        this.slide_manager.previous_slide ();
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

        if (Spice.Application.instance.is_file_opened (file)) {
            Spice.Application.instance.get_window_from_file (file).show_app ();
            this.destroy ();
            return;
        }

        show_editor ();

        slide_manager.reset ();
        history_manager.clear_history ();

        current_file = file;

        string content = Services.FileManager.open_file (current_file);

        slide_manager.load_data (content);
        headerbar.sensitive = true;
        app_stack.set_visible_child_name ("application");

        var basename = current_file.get_basename ();

        var index_of_last_dot = basename.last_index_of (".");
        var launcher_base = (index_of_last_dot >= 0 ? basename.slice (0, index_of_last_dot) : basename);

        title = launcher_base;
        Spice.Application.instance.register_file_to_window (current_file, this);
    }

    public void save_current_file () {
        if (current_file != null) {
            if (slide_manager.slide_count () == 0) {
                Services.FileManager.delete_file (current_file);
            } else {
                Services.FileManager.write_file (current_file, slide_manager.serialise ());
            }
        }
    }

    protected override bool delete_event (Gdk.EventAny event) {
        if (current_file != null) {
            save_current_file ();
            Spice.Application.instance.unregister_file_from_window (current_file);
        }

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

    public void enable_action_group (string[] action_group, bool enabled) {
        foreach (var action in action_group) {
            Utils.set_action_enabled (action, actions, enabled);
        }
    }

    // Actions
    public void action_undo () {
        history_manager.undo ();
    }

    public void action_redo () {
        history_manager.redo ();
    }

    public void action_clone () {
        var current_item = slide_manager.current_item;
        if (current_item != null) {
            Clipboard.duplicate (slide_manager, current_item);
        } else {
            Clipboard.duplicate (slide_manager, slide_manager.current_slide);
        }
    }

    public void action_present_toggle () {
        is_presenting = !is_presenting;
    }

    public void action_toggle_notes () {
        presenter_notes.reveal_child = !presenter_notes.reveal_child;

        if (presenter_notes.reveal_child) {
            presenter_notes.focus_notes ();
        }

        headerbar.notes_shown = presenter_notes.reveal_child;
    }

    public void action_export () {
        Spice.Services.FileManager.export_to_pdf (this.slide_manager);
    }

    public void action_new_slide () {
        Utils.new_slide (slide_manager);
    }

    private void insert_item_action (CanvasItemType type) {
        var item = slide_manager.request_new_item (type);

        if (item != null) {
            toolbar.item_selected (item, true);
        }
    }

    public void action_insert_txt () {
        insert_item_action (CanvasItemType.TEXT);
    }

    public void action_insert_img () {
        insert_item_action (CanvasItemType.IMAGE);
    }

    public void action_insert_shape () {
        insert_item_action (CanvasItemType.SHAPE);
    }

    public void action_bring_fwd () {
        slide_manager.move_up_request ();
    }

    public void action_send_bwd () {
        slide_manager.move_down_request ();
    }

    // Hide cursor while presenting
    uint? hide_id = null;
    bool cursor_hidden = false;
    private bool request_to_hide_mouse (Gdk.Event? event = null) {
        if (cursor_hidden) {
            hide_cursor (false);
        }

        if (hide_id != null) {
            Source.remove (hide_id);
        }

        hide_id = Timeout.add (3000, () => {
            hide_id = null;
            return hide_cursor (true);
        });

        return false;
    }

    private bool hide_cursor (bool hide) {
        if (hide_id != null) {
            Source.remove (hide_id);
            hide_id = null;
        }

        var display = get_display ();
        var cursor = new Gdk.Cursor.for_display (display, hide ? Gdk.CursorType.BLANK_CURSOR : Gdk.CursorType.ARROW);
        get_window ().set_cursor (cursor);
        cursor_hidden = hide;
        return Source.REMOVE;
    }
}
