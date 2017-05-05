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
    private static GamepadSlideController? instance = null;
    private unowned SlideManager slide_manager;

    private LibGamepad.GamepadMonitor gamepad_monitor;
    private LibGamepad.Gamepad[] gamepads = {};

    public static void startup (SlideManager _slide_manager) {
        if (instance == null) {
            instance = new GamepadSlideController ();
        }

        instance.slide_manager = _slide_manager;
    }

    private GamepadSlideController () {
        gamepad_monitor = new LibGamepad.GamepadMonitor ();

        // On plugin, connect signals to the gamepad and store it in the gamepads array so it is not deleted by reference counting
        gamepad_monitor.gamepad_plugged.connect ((gamepad) => {
            print (@"GM Plugged in $(gamepad.raw_gamepad.identifier)- $(gamepad.raw_name)\n");
            gamepads += gamepad;
            // Bind events
            gamepad.button_event.connect (button_event);
            //gamepad.axis_event.connect ((axis, value) => print (@"$(gamepad.raw_name) - $(axis.to_string ()) - $value\n"));
            gamepad.unplugged.connect (() => print (@"$(gamepad.raw_name) - G Unplugged\n"));
            //show_controller_toast ();
        });

        // Initialize initially plugged in gamepads
        gamepad_monitor.foreach_gamepad ((gamepad) => {
            print (@"GM Initially Plugged in $(gamepad.raw_gamepad.identifier) - $(gamepad.guid) - $(gamepad.raw_name)\n");
            gamepads += gamepad;
            // Bind events
            gamepad.button_event.connect (button_event);
            //gamepad.axis_event.connect ((axis, value) => print (@"$(gamepad.name) - $(axis.to_string ()) - $value\n"));
            gamepad.unplugged.connect (() => print (@"$(gamepad.raw_name) - G Unplugged\n"));
            //show_controller_toast ();
        });
    }
    
    Granite.Widgets.Toast toast;
    private void show_controller_toast () {
        toast = new Granite.Widgets.Toast (_("Controller connected"));
        toast.set_default_action (_("Configure"));
    }

    private void button_event (int button) {
        debug ("Gamepad Button event: %d\n", button);

        switch (button) {
            case 0:
                next_slide ();
                break;
            case 2:
                previous_slide ();
                break;
            case 12:
                toggle_present ();
                break;
            case 1:
                jump_to_checkpoint ();
                break;
            case 3:
                set_checkpoint ();
                break;
        }
    }

    private void jump_to_checkpoint () {
        this.slide_manager.jump_to_checkpoint ();
    }

    private void set_checkpoint () {
        this.slide_manager.set_checkpoint ();
    }

    private void next_slide () {
        if (window.is_fullscreen) {
            this.slide_manager.next_slide ();
        }
    }

    private void previous_slide () {
        if (window.is_fullscreen) {
            this.slide_manager.previous_slide ();
        }
    }

    private void toggle_present () {
        if (window.is_fullscreen) {
            window.unfullscreen ();
        } else {
            window.fullscreen ();
        }
    }
}
