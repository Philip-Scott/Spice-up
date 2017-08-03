public class Spice.Utils {
    public static string last_style = "";
    public static void set_style (Gtk.Widget widget, string str) {
        last_style = str;
    }

    public static void set_cursor (Gdk.CursorType type) {}

    public static Json.Object get_json (string data) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (data);

            return parser.get_root ().get_object ();
        } catch (Error e) {
            error ("Invalid json: %s", data);
        }
    }
}

namespace Spice {
    public Spice.Window window;
}

public class Spice.Widgets.CanvasToolbar : Gtk.Box {
    public static string PATTERNS_DIR = "";
}

public class Spice.Window : Gtk.Window {
    public bool is_fullscreen {get; set; default = false; }
    public Window () {}

    static construct {
        window = new Spice.Window ();
    }
}

public class Spice.Services.HistoryManager : Object {
    public const uint MAX_SIZE = 50;

    public signal void action_called (Spice.CanvasItem? item);

    public signal void undo_changed (bool is_empty);
    public signal void redo_changed (bool is_empty);

    public class HistoryAction<I,T> : Object {
        public HistoryAction () {}

        public HistoryAction.item_changed (I item, string property) {}
        public HistoryAction.item_moved (I item, Spice.Canvas? canvas = null, bool? value = null) {}
        public HistoryAction.depth_changed (I item, Spice.Canvas canvas, bool value) {}
    }

    public HistoryManager () {

    }

    public static HistoryManager get_instance () {
        return new HistoryManager ();
    }

    public void add_undoable_action (Object a, Value b = null) {

    }
}
