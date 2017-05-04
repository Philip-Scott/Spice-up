/*
 * Copyright 2017 Felipe Escoto
 *           2016 Megh Parikh
 *
 *
 * This file is part of LibGamepad.
 *
 * LibGamepad is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * LibGamepad is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * This class represents a simplified gamepad
 *
 * The client interfaces with this class primarily
 */
public class LibGamepad.Gamepad : Object {
    /**
     * Emitted when a button is pressed
     * @param  button        The button pressed
     */
    public signal void button_event (int button);

    /**
     * Emitted when the gamepad is unplugged
     */
    public signal void unplugged ();


    /**
     * The raw name reported by the driver
     */
    public string? raw_name { get; private set; }

    /**
     * The guid
     */
    public string? guid { get; private set; }

    /**
     * The raw gamepad behind this gamepad
     */
    public RawGamepad raw_gamepad { get; private set; }

    public Gamepad (RawGamepad raw_gamepad) {
        this.raw_gamepad = raw_gamepad;
        raw_name = raw_gamepad.name;
        guid = raw_gamepad.guid;

        raw_gamepad.button_event.connect (on_raw_button_event);
        //raw_gamepad.axis_event.connect (on_raw_axis_event);
        //raw_gamepad.dpad_event.connect (on_raw_dpad_event);

        raw_gamepad.unplugged.connect (() => unplugged ());
    }

    Gee.HashSet<int> pressed_buttons = new Gee.HashSet<int>();
    private void on_raw_button_event (int button, bool value) {
        if (value && !pressed_buttons.contains (button)) {
            pressed_buttons.add (button);
            debug ("Raw button pressed event: %d", button);
            button_event (button);
        } else if (!value) {
            pressed_buttons.remove (button);
            debug ("Raw button released event: %d", button);
        }
    }
/*
    private void on_raw_axis_event (int axis, double value) {
        debug ("On raw axis event: %d %s", axis, value.to_string ());

        //mapping.get_axis_mapping (axis, out type, out output_axis, out output_button);
        //emit_event (type, output_axis, output_button, value);
    }

    private void on_raw_dpad_event (int dpad_index, int axis, int value) {
        InputType type;
        StandardGamepadAxis output_axis;
        StandardGamepadButton output_button;

        mapping.get_dpad_mapping (dpad_index, axis, value, out type, out output_axis, out output_button);
        emit_event (type, output_axis, output_button, value.abs ());
    }

    private void emit_event (InputType type, StandardGamepadAxis axis, StandardGamepadButton button, double value) {
        switch (type) {
        case InputType.AXIS:
            axis_event (axis, value);
            break;
        case InputType.BUTTON:
            button_event (button, (bool) value);
            break;
        }*/

}
