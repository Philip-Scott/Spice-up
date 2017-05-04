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
 * This interface deals with handling events related to plugging and unplugging
 * of gamepads and also provides a method to iterate through all the plugged in
 * gamepads. An identifier is a string that is easily understood by the driver
 * and may depend on other factors, i.e. it may not be unique for the gamepad.
 */
public interface LibGamepad.RawGamepadMonitor : Object {
	/**
	 * This signal should be emmited when a gamepad is plugged in.
	 * @param   raw_gamepad   The raw gamepad
	 */
	public abstract signal void gamepad_plugged (RawGamepad raw_gamepad);

	/**
	 * This signal should be emitted when a gamepad is unplugged
	 *
	 * If an identifier which is not passed with gamepad_plugged even once is passed,
	 * then it is ignored. Drivers may use this to their benefit
	 *
	 * @param  identifier    The identifier of the unplugged gamepad
	 */
	public abstract signal void gamepad_unplugged (string identifier);

	public delegate void RawGamepadCallback (RawGamepad raw_gamepad);

	/**
	 * This function allows to iterate over all gamepads
	 * @param   callback            The callback
	 */
	public abstract void foreach_gamepad (RawGamepadCallback callback);
}
