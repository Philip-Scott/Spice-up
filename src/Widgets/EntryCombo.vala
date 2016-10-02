/*
* Copyright (c) 2016 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

public class Spice.EntryCombo : Gtk.Box {
    public signal void activated (string data);

    public string text {
        get {
            return entry.text;
        }
        set {
            outsize_set = true;

            if (map.has_key (value.down())) {
                listbox.select_row (map.get (value.down()));
                entry.text = ((Gtk.Label) map.get (value.down()).get_child ()).label;
            } else if (!strict_signal){
                entry.text = value;
            }

            outsize_set = false;
        }
    }

    public int max_length {
        get {
            return entry.max_length;
        }
        set {
            //entry.max_length = value;
            entry.max_width_chars = value + 1;
            entry.width_chars = value;
        }
    }

    public bool editable {
        get {
            return entry.editable;
        }
        set {
            entry.sensitive = value;
        }
    }

    private Gtk.ScrolledWindow scroll;
    private Gtk.Popover popover;
    private Gtk.ListBox listbox;
    private Gtk.Entry entry;
    private Gtk.Button button;

    private Gee.HashMap<string, Gtk.ListBoxRow> map;
    private bool outsize_set = false;
    private bool strict_signal = false;

    // If strict_signal == true, it will only send activated if the entry is the same as a value on the list
    public EntryCombo (bool strict_signal = false, bool alphabetize = false) {
        this.strict_signal = strict_signal;
    
        map = new Gee.HashMap<string, Gtk.ListBoxRow> ();

        entry = new Gtk.Entry ();

        listbox = new Gtk.ListBox ();
        listbox.set_activate_on_single_click (false);

        button = new Gtk.Button.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU);
        button.can_focus = false;

        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.height_request = 220;

        popover = new Gtk.Popover (button);
        popover.position = Gtk.PositionType.BOTTOM;

        orientation = Gtk.Orientation.HORIZONTAL;
        get_style_context ().add_class ("linked");

        button.clicked.connect (() => {
            popover.show_all ();
        });

        entry.changed.connect (() => {
            if (outsize_set) return;
            text = entry.text;
            if (strict_signal) {
                activated (entry.text);
            } else {
                activated (entry.text);
            }
        });

        listbox.row_selected.connect ((row) => {
            if (outsize_set) return;
            var label = (Gtk.Label) row.get_child ();
            text = label.label;
            activated (label.label);
        });

        listbox.row_activated.connect ((row) => {
            popover.hide ();
        });

        if (alphabetize == true) {
            listbox.set_sort_func ((row1, row2) => {
                return strcmp (((Gtk.Label) row1.get_child ()).label, ((Gtk.Label) row2.get_child ()).label);
            });
        }

        scroll.add (listbox);
        popover.add (scroll);
        base.add (entry);
        base.add (button);
        show_all ();
    }

    public void clear_all () {
        outsize_set = true;
        map = new Gee.HashMap<string, Gtk.ListBoxRow> ();
        foreach (var child in listbox.get_children ()) {
            if (child is Gtk.ListBoxRow)
                child.destroy ();
        }

        outsize_set = false;
    }

    public Gtk.Label? add_entry (string entry) {
        var label = new Gtk.Label (entry);
        if (entry.contains ("Noto Sans") && entry != "Noto Sans") return label;

        var row = new Gtk.ListBoxRow ();
        map.set (entry.down(), row);

        row.add (label);
        listbox.add (row);
        listbox.show_all ();

        return label;
    }
}
