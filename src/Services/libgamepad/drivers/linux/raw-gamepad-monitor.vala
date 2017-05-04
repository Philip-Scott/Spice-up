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

private class LibGamepad.LinuxRawGamepadMonitor : Object, RawGamepadMonitor {
	public delegate void RawGamepadCallback (RawGamepad raw_gamepad);

	private GUdev.Client client;

	public LinuxRawGamepadMonitor () {
		client = new GUdev.Client ({"input"});
		client.uevent.connect (handle_udev_client_callback);
	}

	public void foreach_gamepad (RawGamepadCallback callback) {
		client.query_by_subsystem ("input").foreach ((dev) => {
			if (dev.get_device_file () == null)
				return;
			var identifier = dev.get_device_file ();
			if ((dev.has_property ("ID_INPUT_JOYSTICK") && dev.get_property ("ID_INPUT_JOYSTICK") == "1") ||
				(dev.has_property (".INPUT_CLASS") && dev.get_property (".INPUT_CLASS") == "joystick")) {
				RawGamepad raw_gamepad;
				try {
					raw_gamepad = new LinuxRawGamepad (identifier);
				} catch (FileError err) {
					return;
				}
				callback (raw_gamepad);
			}
		});
	}

	private void handle_udev_client_callback (string action, GUdev.Device dev) {
		if (dev.get_device_file () == null)
			return;

		var identifier = dev.get_device_file ();
		if ((dev.has_property ("ID_INPUT_JOYSTICK") && dev.get_property ("ID_INPUT_JOYSTICK") == "1") ||
			(dev.has_property (".INPUT_CLASS") && dev.get_property (".INPUT_CLASS") == "joystick")) {
			switch (action) {
			case "add":
				RawGamepad raw_gamepad;
				try {
					raw_gamepad = new LinuxRawGamepad (identifier);
				} catch (FileError err) {
					return;
				}
				gamepad_plugged (raw_gamepad);
				break;
			case "remove":
				gamepad_unplugged (identifier);
				break;
			}
		}
	}
}
