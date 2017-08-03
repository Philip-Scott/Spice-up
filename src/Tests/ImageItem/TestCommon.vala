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

public class Spice.Services.HistoryManager : Object {
    public const uint MAX_SIZE = 50;

    public signal void action_called (Spice.CanvasItem? item);

    public signal void undo_changed (bool is_empty);
    public signal void redo_changed (bool is_empty);

    public class HistoryAction<I,T> : Object {
        public HistoryAction () {}

        public HistoryAction.item_changed (I item, string property) {}
    }

    public HistoryManager () {

    }

    public static HistoryManager get_instance () {
        return new HistoryManager ();
    }

    public void add_undoable_action (Object a, Value b) {

    }
}
