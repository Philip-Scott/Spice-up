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

    private string key;

    public string text {
        get {
            if (keys.has_key (entry.text.down ())) {
                key = keys.get (entry.text.down ());
                return key;
            } else
                return entry.text;
        }

        set {
            outsize_set = true;
            var new_val = value.down ();
            if (map.has_key (new_val)) {
                listbox.select_row (map.get (new_val));
                entry.text = ((Gtk.Label) map.get (new_val).get_child ()).label;
                substitute_label.label = entry.text;
            } else if (!strict_signal){
                listbox.select_row (null);
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

            if (value) {
                entry_button_stack.set_visible_child_name ("entry");
            } else {
                entry_button_stack.set_visible_child_name ("button");
            }
        }
    }

    private Gtk.Stack entry_button_stack;
    private Gtk.ScrolledWindow scroll;
    private Gtk.Popover popover;
    private Gtk.ListBox listbox;
    private Gtk.Entry entry;
    private Gtk.Button button;
    private Gtk.Label substitute_label;

    private Gee.HashMap<string, Gtk.ListBoxRow> map;
    private Gee.HashMap<string, string> keys;
    private bool outsize_set = false;
    private bool strict_signal = false;

    // If strict_signal == true, it will only send activated if the entry is the same as a value on the list
    public EntryCombo (bool strict_signal = false, bool alphabetize = false) {
        this.strict_signal = strict_signal;

        map = new Gee.HashMap<string, Gtk.ListBoxRow> ();
        keys = new Gee.HashMap<string, string> ();

        entry_button_stack = new Gtk.Stack ();
        entry_button_stack.margin = 3;

        entry = new Gtk.Entry ();

        listbox = new Gtk.ListBox ();
        listbox.set_activate_on_single_click (false);

        substitute_label = new Gtk.Label ("");
        substitute_label.halign = Gtk.Align.START;

        var entry_substitute = new Gtk.Button ();
        entry_substitute.get_style_context ().remove_class ("button");
        entry_substitute.get_style_context ().add_class ("entry");
        entry_substitute.add (substitute_label);
        entry_substitute.can_focus = false;

        button = new Gtk.Button.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU);
        button.get_style_context ().remove_class ("button");
        button.get_child ().margin = 4;
        button.can_focus = false;

        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.vscrollbar_policy = Gtk.PolicyType.NEVER;

        popover = new Gtk.Popover (button);
        popover.position = Gtk.PositionType.BOTTOM;

        orientation = Gtk.Orientation.HORIZONTAL;
        get_style_context ().add_class ("frame");

        button.clicked.connect (() => {
            popover.show_all ();
        });

        entry_substitute.clicked.connect (() => {
            popover.show_all ();
        });

        entry.changed.connect (() => {
            if (outsize_set) return;
            text = entry.text;
            if (strict_signal && keys.has_key (text.down ())) {
                activated (entry.text);
            } else if (!strict_signal){
                activated (entry.text);
            }
        });

        listbox.row_selected.connect ((row) => {
            if (outsize_set) return;
            var label = (Gtk.Label) row.get_child ();
            text = keys.get (label.label.down ());

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

        entry_button_stack.add_named (entry, "entry");
        entry_button_stack.add_named (entry_substitute, "button");

        base.add (entry_button_stack);
        base.add (button);
        show_all ();

        entry_button_stack.set_visible_child_name ("entry");
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
    /*
    Label -> Translated
    Key -> Real Value

    Map <RealValue, ListBoxRow>
    Keys <Translated, RealValue>*/
                                // Key = real value, entry = translated
    public Gtk.Label? add_entry (string real, string? translated = null) {
        if (translated == null) translated = real;

        keys.set (translated.down (), real.down ());

        var label = new Gtk.Label (translated);
        label.margin = 2;
        label.margin_right = 6;
        label.margin_left = 6;

        if (translated.contains ("Noto Sans") && translated != "Noto Sans") return label;

        var row = new Gtk.ListBoxRow ();
        map.set (real.down (), row);

        row.add (label);
        listbox.add (row);
        listbox.show_all ();

        if (listbox.get_children().length () > 15) {
            scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            scroll.height_request = 220;
        }

        return label;
    }
}
