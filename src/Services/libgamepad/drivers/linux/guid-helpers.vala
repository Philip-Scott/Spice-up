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

private class LibGamepad.LinuxGuidHelpers : Object {
	public static string from_dev (Libevdev.Evdev dev) {
		uint16 guid[8];
		guid[0] = (uint16) dev.id_bustype.to_little_endian ();
		guid[1] = 0;
		guid[2] = (uint16) dev.id_vendor.to_little_endian ();
		guid[3] = 0;
		guid[4] = (uint16) dev.id_product.to_little_endian ();
		guid[5] = 0;
		guid[6] = (uint16) dev.id_version.to_little_endian ();
		guid[7] = 0;
		return uint16s_to_hex_string (guid);
	}

	public static string from_file (string file_name) throws FileError {
		var fd = Posix.open (file_name, Posix.O_RDONLY | Posix.O_NONBLOCK);

		if (fd < 0)
			throw new FileError.FAILED (@"Unable to open file $file_name: $(Posix.strerror (Posix.errno))");

		var dev = new Libevdev.Evdev ();
		if (dev.set_fd (fd) < 0)
			throw new FileError.FAILED (@"Evdev error on opening file $file_name: $(Posix.strerror (Posix.errno))");

		var guid = from_dev (dev);
		Posix.close (fd);
		return guid;
	}
}
