/*-
 * Copyright 2019 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

[DBus (name = "org.freedesktop.ScreenSaver")]
private interface Granite.Staging.Services.ScreenSaverIface : Object {
    public abstract uint32 Inhibit (string app_name, string reason) throws Error;
    public abstract void UnInhibit (uint32 cookie) throws Error;
}

public class Granite.Staging.Services.Inhibitor :  Object {
    private const string IFACE = "org.freedesktop.ScreenSaver";
    private const string IFACE_PATH = "/ScreenSaver";

    private static Inhibitor? instance = null;

    private uint32? screensaver_inhibit_cookie = null;
    private uint32? suspend_inhibit_cookie = null;
    private bool inhibited = false;

    private Granite.Staging.Services.ScreenSaverIface? screensaver_iface = null;

    private unowned Gtk.Application application;

    private Inhibitor (Gtk.Application _application) {
        this.application = _application;

        try {
            screensaver_iface = Bus.get_proxy_sync (BusType.SESSION, IFACE, IFACE_PATH, DBusProxyFlags.NONE);
        } catch (Error e) {
            warning ("Could not start screensaver interface: %s", e.message);
        }
    }

    public static void initialize (Gtk.Application _application) {
        if (instance == null) {
            instance = new Granite.Staging.Services.Inhibitor (_application);
        }
    }

    public static unowned Inhibitor get_instance () {
        return instance;
    }

    public void inhibit (string reason) {
        if (screensaver_iface != null && !inhibited) {
            try {
                inhibited = true;
                screensaver_inhibit_cookie = screensaver_iface.Inhibit (application.application_id, reason);
                suspend_inhibit_cookie = application.inhibit (application.get_active_window (), Gtk.ApplicationInhibitFlags.SUSPEND, reason);
                debug ("Inhibiting screen");
            } catch (Error e) {
                warning ("Could not inhibit screen: %s", e.message);
            }
        }
    }

    public void uninhibit () {
        inhibited = false;

        if (screensaver_iface != null && screensaver_inhibit_cookie != null) {
            try {
                screensaver_iface.UnInhibit (screensaver_inhibit_cookie);
                application.uninhibit (suspend_inhibit_cookie);
                screensaver_inhibit_cookie = null;
                suspend_inhibit_cookie = null;
                debug ("Uninhibiting screen");
            } catch (Error e) {
                warning ("Could not uninhibit screen: %s", e.message);
            }
        }
    }
}
