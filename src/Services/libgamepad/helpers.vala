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

namespace LibGamepad {
	private const int GUID_LENGTH = 8;

	private string uint16s_to_hex_string (uint16[] data)
	               requires (data.length == GUID_LENGTH)
	{
		const string k_rgchHexToASCII = "0123456789abcdef";

		var builder = new StringBuilder ();
		for (var i = 0; i < GUID_LENGTH; i++) {
			uint8 c = (uint8) data[i];
			builder.append_unichar (k_rgchHexToASCII[c >> 4]);
			builder.append_unichar (k_rgchHexToASCII[c & 0x0F]);

			c = (uint8) (data[i] >> 8);
			builder.append_unichar (k_rgchHexToASCII[c >> 4]);
			builder.append_unichar (k_rgchHexToASCII[c & 0x0F]);
		}
		return builder.str;
	}
}
