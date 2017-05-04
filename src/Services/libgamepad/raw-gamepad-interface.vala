/*
 * Copyright 2016 Megh Parikh
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
 * This is one of the interfaces that needs to be implemented by the driver.
 *
 * This interface represents a gamepad and deals with handling events that are
 * emitted by a gamepad and also provide properties like name and guid along
 * with number of buttons, axes and dpads.
 *
 * The constructor takes a identifier as a parameter.
 * @see RawGamepadMonitor
 */
public interface LibGamepad.RawGamepad : Object {
	/**
	 * Emitted when a button is pressed/released
	 * @param  code          The button code from 0 to buttons_number
	 * @param  value         True if pressed, False if released
	 */
	public abstract signal void button_event (int code, bool value);

	/**
	 * Emitted when an axis's value changes
	 * @param  axis          The axis number from 0 to axes_number
	 * @param  value         The value of the axis ranging from -1 to 1
	 */
	public abstract signal void axis_event (int axis, double value);

	/**
	 * Emitted when a dpad's axis's value changes
	 * @param  dpad          The dpad number from 0 to
	 * @param  axis          The axis: 0 for X, 1 for Y
	 * @param  value         The value of the axis ranging from -1 to 1
	 */
	public abstract signal void dpad_event (int dpad, int axis, int value);

	/**
	 * Emitted when the gamepad is unplugged
	 */
	public abstract signal void unplugged ();

	public abstract string identifier { get; }
	public abstract string name { get; }
	public abstract string guid { get; }

	/**
	 * Number of axes of the gamepad
	 */
	public abstract uint8 axes_number { get; }

	/**
	 * Number of buttons of the gamepad
	 */
	public abstract uint8 buttons_number { get; }

	/**
	 * Number of dpads of the gamepad`
	 */
	public abstract uint8 dpads_number { get; }
}
