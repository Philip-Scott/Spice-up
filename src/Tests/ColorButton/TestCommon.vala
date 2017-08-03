public class Spice.Utils {
    public static string last_style = "";
    public static void set_style (Gtk.Widget widget, string str) {
        last_style = str;
    }

    public static Json.Object get_json (string data) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (data);

            return parser.get_root ().get_object ();
        } catch (Error e) {
            error ("Invalid json");
        }
    }
}

public class Spice.Canvas : Object {
    public signal void ratio_changed (double ratio);
    public double current_ratio { get; set; default = 2.0;}
}
