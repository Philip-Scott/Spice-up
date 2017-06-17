

[DBus (name = "org.freedesktop.thumbnails.Thumbnailer1.spiceup")]
public class Spice.Tumbler : GLib.Object {
    public async uint Queue (string[] uris, string[] mime_types, string flavor, string sheduler, uint handle) throws GLib.IOError, GLib.DBusError {
        stderr.printf ("Requesting file! \n");
        var files = new List<File>();
    
        files.append (File.new_for_uri ("file:///home/felipe/FirstPresentation.spice"));
        files.append (File.new_for_uri ("file:///home/felipe/FirstPresentation.png"));

        Spice.Services.Thumbnailer.run (files);

        return 0;
    }
}

public class Spice.DbusThumbnailer : GLib.Object {
    private const string THUMBNAILER_IFACE = "org.freedesktop.thumbnails.Thumbnailer1.spiceup";
    private const string THUMBNAILER_SERVICE = "/org/freedesktop/thumbnails/Thumbnailer1/spiceup";

    private const uint THUMBNAIL_MAX_QUEUE_SIZE = 50;
    
    Spice.Tumbler tumbler;
    
    public DbusThumbnailer (string flavor = "normal") throws GLib.Error {
        tumbler = new Spice.Tumbler ();
    
        Bus.own_name (BusType.SESSION, THUMBNAILER_IFACE, BusNameOwnerFlags.NONE,
                      on_bus_aquired,
                      () => {},
                      () => stderr.printf ("Could not aquire name\n"));
    }

    void on_bus_aquired (DBusConnection conn) {
        stderr.printf ("dbus aquired\n");

        try {
            conn.register_object (THUMBNAILER_SERVICE, tumbler);
        } catch (IOError e) {
            stderr.printf ("Could not register service\n");
        }
    }
}
