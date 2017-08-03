public class Spice.Utils {
    public static string last_style = "";
    public static void set_style (Gtk.Widget widget, string str) {
        last_style = str;
    }
}

public abstract class Spice.CanvasItem : Gtk.Widget {
    public Json.Object? save_data;

    public CanvasItem (Canvas canvas) {}

    public void load_data () {
        if (save_data != null) {
            load_item_data ();
        }
    }

    protected abstract string serialise_item ();
    protected virtual void load_item_data () {}
    public new virtual void style () {}
}
public class Spice.Canvas : Object {}
