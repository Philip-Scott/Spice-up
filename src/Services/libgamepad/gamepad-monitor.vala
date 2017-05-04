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
 * This class provides a way to the client to monitor gamepads
 *
 * The client interfaces with this class primarily
 */
public class LibGamepad.GamepadMonitor : Object {
	/**
	 * Emitted when a gamepad is plugged in
	 * @param  gamepad    The gamepad
	 */
	public signal void gamepad_plugged (Gamepad gamepad);

	/**
	 * Emitted when a gamepad is unplugged
	 * @param  identifier    The identifier of the unplugged gamepad
	 * @param  guid          The guid of the unplugged gamepad
	 * @param  name          The name of the unplugged gamepad
	 */
	public signal void gamepad_unplugged (string identifier, string guid, string? name);

	public delegate void GamepadCallback (Gamepad gamepad);

	private static HashTable<string, RawGamepad> identifier_to_raw_gamepad;
	private static HashTable<string, string> guid_to_raw_name;

	/**
	 * The number of plugged in gamepads
	 */
	public uint gamepads_number { get; private set; default = 0; }

	private RawGamepadMonitor raw_gamepad_monitor;

	public GamepadMonitor () {
		init_static_if_not ();

		raw_gamepad_monitor = new LinuxRawGamepadMonitor ();

		raw_gamepad_monitor.gamepad_plugged.connect (on_raw_gamepad_plugged);
		raw_gamepad_monitor.gamepad_unplugged.connect (on_raw_gamepad_unplugged);

		raw_gamepad_monitor.foreach_gamepad ((raw_gamepad) => {
			add_gamepad (raw_gamepad);
		});

	}

	/**
	 * This static function returns a raw gamepad given a guid. It can be used
	 * for creating interfaces for remappable-controls.
	 * @param  identifier         The identifier of the raw gamepad that you want
	 */
	public static RawGamepad? get_raw_gamepad (string identifier) {
		init_static_if_not ();

		if (identifier == null)
			return null;
		else
			return identifier_to_raw_gamepad.get (identifier);
	}

	private static void init_static_if_not () {
		if (identifier_to_raw_gamepad == null)
			identifier_to_raw_gamepad = new HashTable<string, RawGamepad> (str_hash, str_equal);
		if (guid_to_raw_name == null)
			guid_to_raw_name = new HashTable<string, string> (str_hash, str_equal);
	}

	/**
	 * This function allows to iterate over all gamepads
	 * @param    callback          The callback
	 */
	public void foreach_gamepad (GamepadCallback callback) {
		identifier_to_raw_gamepad.foreach ((identifier, raw_gamepad) => {
			callback (new Gamepad (raw_gamepad));
		});
	}

	private void add_gamepad (RawGamepad raw_gamepad) {
		gamepads_number++;
		identifier_to_raw_gamepad.replace (raw_gamepad.identifier, raw_gamepad);
		guid_to_raw_name.replace (raw_gamepad.guid.to_string (), raw_gamepad.name);
	}

	private void on_raw_gamepad_plugged (RawGamepad raw_gamepad) {
		add_gamepad (raw_gamepad);
		gamepad_plugged (new Gamepad (raw_gamepad));
	}

	private void on_raw_gamepad_unplugged (string identifier) {
		var raw_gamepad = identifier_to_raw_gamepad.get (identifier);
		if (raw_gamepad == null)
			return;
		gamepads_number--;
		guid_to_raw_name.remove (raw_gamepad.guid.to_string ());
		gamepad_unplugged (raw_gamepad.identifier, raw_gamepad.guid, raw_gamepad.name);
	}
}
