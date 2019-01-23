/*
* Copyright (c) 2018 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

public class Spice.Welcome : Gtk.Box {
    private const string TEMPLATES_URL = "https://spice-up-dev.azurewebsites.net/api/get-templates";

    public signal void open_file (File file);

    private Granite.Widgets.Welcome welcome;
    private Spice.Widgets.Library.Library? library = null;
    private Spice.Widgets.Library.Library? templates = null;
    private Spice.Services.Fetcher fetcher;
    private Gtk.Separator separator;
    private Gtk.Stack welcome_stack;

    public Welcome () {
        fetcher = new Spice.Services.Fetcher ();
        fetcher.fetch_templates ();

        orientation = Gtk.Orientation.HORIZONTAL;
        get_style_context ().add_class ("view");

        width_request = 950;
        height_request = 500;

        welcome = new Granite.Widgets.Welcome ("Spice-Up", _("Make a Simple Presentation"));
        welcome.hexpand = true;

        welcome.append ("document-new", _("New Presentation"), _("Create a new presentation"));
        welcome.append ("folder-open", _("Open File"), _("Open a saved presentation"));

        separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);

        welcome_stack = new Gtk.Stack ();
        welcome_stack.add_named (welcome, "welcome");
        welcome_stack.set_visible_child (welcome);

        add (welcome_stack);
        add (separator);

        welcome.activated.connect ((index) => {
            switch (index) {
                case 0:
                    show_templates ();
                    break;
                case 1:
                    var file = Spice.Services.FileManager.open_presentation ();
                    if (file != null) open_file (file);
                    break;
             }
        });
    }

    public void show_templates () {
        if (templates == null) {
            templates = new Spice.Widgets.Library.Library.for_templates ();
            welcome_stack.add_named (templates, "templates");
            welcome_stack.show_all ();

            templates.item_selected.connect ((data) => {
                var file = Spice.Services.FileManager.new_presentation (data);
                if (file != null) {
                    open_file (file);
                }
            });

            load_remote_templates ();
        }

        welcome_stack.set_visible_child_full ("templates", Gtk.StackTransitionType.SLIDE_RIGHT);
    }

    public void reload () {
        var files = settings.last_files;
        welcome_stack.set_visible_child_full ("welcome", Gtk.StackTransitionType.NONE);

        if (library != null) {
            remove (library);
            library.destroy ();
            library = null;
        }

        if (files.length > 0 && Granite.Services.System.history_is_enabled () == false) {
            library = new Spice.Widgets.Library.Library (files);
            add (library);

            library.file_selected.connect ((file) => {
                open_file (file);
            });

            separator.visible = true;
            separator.no_show_all = false;

            this.show_all ();
        } else {
            separator.visible = false;
            separator.no_show_all = true;
        }
    }

    private void load_remote_templates () {
        var template_data = fetcher.get_data ();
        if (template_data == null) return;

        var json_data = Spice.Utils.get_json_object (template_data);

        if (json_data == null) return;

        if (json_data.get_string_member ("version") != Spice.Services.Fetcher.CURRENT_VERSION) return;

        var templates_array = json_data.get_array_member ("templates");

        Idle.add (() => {
            foreach (var raw in templates_array.get_elements ()) {
                var template = raw.get_object ();
                templates.add_remote (
                    template.get_string_member ("name"),
                    template.get_string_member ("url"),
                    template.get_string_member ("preview")
                );
            }
            return GLib.Source.REMOVE;
        });
    }
}