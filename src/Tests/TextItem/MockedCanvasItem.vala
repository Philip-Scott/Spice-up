public abstract class Spice.CanvasItem : Gtk.EventBox {
    public signal void clicked ();
    protected signal void un_select ();

    public Json.Object? save_data { get; construct; }
    public Canvas canvas { get; set; }
    protected Gtk.Grid? grid = null;

    protected CanvasItem (Canvas canvas, Json.Object save_data) {
        Object (canvas: _canvas, save_data: _save_data);
    }

    public void load_data () {
        load_item_data ();
    }

    public string serialise () {
        return "{%s}".printf (serialise_item ());
    }

    protected abstract string serialise_item ();
    protected virtual void load_item_data () {}
    public new virtual void style () {}
}
