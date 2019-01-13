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

public class Spice.GamepadSlideController : Object {
    public signal void raw_button (int button);

    private static Spice.GamepadSlideController? instance = null;
    private unowned Spice.SlideManager slide_manager;
    private unowned Spice.Window window;

    private LibGamepad.GamepadMonitor gamepad_monitor;
    private LibGamepad.Gamepad[] gamepads = {};

    private Granite.Widgets.Toast? toast = null;
    private ControlerConfiguration? config = null;

    public bool editing = false;

    public static void startup (SlideManager _slide_manager, Spice.Window window) {
        if (instance == null) {
            instance = new GamepadSlideController (window);
        }

        instance.slide_manager = _slide_manager;
    }

    private GamepadSlideController (Spice.Window window) {
        this.window = window;
        gamepad_monitor = new LibGamepad.GamepadMonitor ();

        gamepad_monitor.gamepad_plugged.connect (connect_gamepad);
        gamepad_monitor.foreach_gamepad (connect_gamepad);
    }

    private void connect_gamepad (LibGamepad.Gamepad gamepad) {
        debug ("Controler Plugged in %s, %s", gamepad.raw_gamepad.identifier, gamepad.raw_name);
        gamepads += gamepad;

        config = new ControlerConfiguration ();

        gamepad.button_event.connect (button_event);
        gamepad.unplugged.connect (() => debug (@"$(gamepad.raw_name) - G Unplugged\n"));
        show_controller_toast ();
    }

    private void show_controller_toast () {
        if (toast == null) {
            toast = new Granite.Widgets.Toast (_("Controller found"));
            toast.set_default_action (_("Set up…"));

            toast.default_action.connect (() => {
                var dialog = new ControllerConfigurationDialog (this, this.config);
                dialog.present ();
            });
        }

        this.window.add_toast_notification (toast);
    }

    private void button_event (int button) {
        debug ("Gamepad Button event: %d\n", button);
        raw_button (button);
        if (editing) return;

        if (button == config.next) {
            next_slide ();
        } else if (button == config.back) {
            previous_slide ();
        } else if (button == config.checkpoint) {
            set_checkpoint ();
        } else if (button == config.jump) {
            jump_to_checkpoint ();
        } else if (button == config.home) {
            toggle_present ();
        }
    }

    private void jump_to_checkpoint () {
        this.slide_manager.jump_to_checkpoint ();
    }

    private void set_checkpoint () {
        this.slide_manager.set_checkpoint ();
    }

    private void next_slide () {
        if (window.is_presenting) {
            this.slide_manager.next_slide ();
        }
    }

    private void previous_slide () {
        if (window.is_presenting) {
            this.slide_manager.previous_slide ();
        }
    }

    private void toggle_present () {
        if (window.is_presenting) {
            window.unfullscreen ();
        } else {
            window.fullscreen ();
        }
    }

    private class ControllerConfigurationDialog : Gtk.Dialog {
        private unowned ControlerConfiguration config;
        private unowned GamepadSlideController monitor;

        private Gtk.Grid grid;
        private Gtk.Widget save_button;

        private bool listening = false;
        private int** listening_action = null;
        private Gtk.Button listening_button;

        private int row = 0;

        public ControllerConfigurationDialog (GamepadSlideController monitor, ControlerConfiguration _config) {
            this.monitor = monitor;
            this.config = _config;

            monitor.editing = true;

            this.set_border_width (12);
            set_titlebar (new Gtk.Grid ());
            set_keep_above (true);
            set_size_request (360, 400);
            resizable = false;
            modal = true;

            var label = new Gtk.Label (_("Controller Configuration"));
            label.get_style_context ().add_class ("h4");

            this.grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.column_spacing = 12;
            grid.row_spacing = 6;

            grid.attach (label, 0, row++, 1, 1);
            add_row (_("Next Slide:"), &(config.next));
            add_row (_("Previous Slide:"), &(config.back));
            add_row (_("Set Jump:"), &(config.checkpoint));
            add_row (_("Jump to slide:"), &(config.jump));
            add_row (_("Toggle Presentation:"), &(config.home));

            get_content_area ().add (grid);
            add_button (_("Cancel"), 2);
            save_button = add_button (_("Apply"), 1);

            response.connect ((ID) => {
                switch (ID) {
                case 1:
                    config.save ();
                    break;
                }

                listening = false;
                monitor.editing = false;
                this.close ();
            });

            monitor.raw_button.connect ((id) => {
                if (!this.listening) return;
                this.listening = false;

                debug ("Event caught %d\n", id);

                **listening_action = id;
                listening_button.label = _("Button %d").printf (id);

                save_button.sensitive = config.is_valid ();
            });

            this.show_all ();
        }

        public void add_row (string name, int* action) {
            var label = new Gtk.Label (name);
            label.halign = Gtk.Align.END;

            var button = new Gtk.Button.with_label (_("Button %d").printf (*action));
            button.clicked.connect (() => {
                if (listening) {
                    listening_button.label = _("Button %d").printf (**listening_action);
                }

                if (!listening || this.listening_button != button) {
                    this.listening = true;
                    this.listening_action = &action;
                    this.listening_button = button;
                    button.label = _("...");
                    save_button.sensitive = false;
                } else if (listening && this.listening_button == button) {
                    this.listening = false;
                    this.listening_button = null;
                    save_button.sensitive = config.is_valid ();
                }
            });

            this.grid.attach (label, 0, row, 1, 1);
            this.grid.attach (button, 1, row++, 1, 1);
        }
    }

    private class ControlerConfiguration : Object {
        // Defaults to JoyCon's Configuration
        public int next = 0;
        public int back = 2;
        public int checkpoint = 3;
        public int jump = 1;
        public int home = 12;

        public ControlerConfiguration () {
            load ();
        }

        public bool is_valid () {
            var buttons = new Array<int>();
            buttons.append_val (next);

            if (back in buttons.data) return false;
            buttons.append_val (back);

            if (checkpoint in buttons.data) return false;
            buttons.append_val (checkpoint);

            if (jump in buttons.data) return false;
            buttons.append_val (jump);

            if (home in buttons.data) return false;
            buttons.append_val (home);

            return true;
        }

        public void load () {
            var config = Spice.Services.Settings.get_instance ().controler_config;
            if (config == "") {
                save ();
                return;
            }

            try {
                var parser = new Json.Parser ();
                parser.load_from_data (config);

                var root = parser.get_root ().get_object ();

                next = (int) root.get_int_member ("next");
                back = (int) root.get_int_member ("back");
                checkpoint = (int) root.get_int_member ("checkpoint");
                jump = (int) root.get_int_member ("jump");
                home = (int) root.get_int_member ("home");
            } catch (Error e) {
                warning ("Error loading controler config: %s", e.message);
                save ();
            }
        }

        public void save () {
            var config = """{"next":%d, "back":%d, "checkpoint":%d, "jump":%d, "home":%d }""".printf (next, back, checkpoint, jump, home);
            Spice.Services.Settings.get_instance ().controler_config = config;
        }
    }
}
