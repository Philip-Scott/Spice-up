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

public const string APP_NAME = "Spice-Up";
public const string TERMINAL_NAME = "spice-up";

public static bool DEBUG = false;

public static int main (string[] args) {
    DEBUG = "-d" in args;

    /* Initiliaze gettext support */
    Intl.setlocale (LocaleCategory.ALL, Intl.get_language_names ()[0]);
    //Intl.setlocale (LocaleCategory.NUMERIC, "en_US");
    //Intl.textdomain (TERMINAL_NAME);

    Environment.set_application_name (APP_NAME);
    Environment.set_prgname (APP_NAME);

    var application = Spice.Application.instance;

    return application.run (args);
}
