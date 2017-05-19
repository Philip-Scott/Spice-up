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

public class Spice.DynamicToolbar : Gtk.Box {
    private string TEXT = "text";
    private string IMAGE = "image";
    private string SHAPE = "shape";
    private string CANVAS = "canvas";

    private SlideManager manager;
    private Gtk.Stack stack;

    private Spice.Widgets.Toolbar text_bar;
    private Spice.Widgets.Toolbar shape_bar;
    private Spice.Widgets.Toolbar image_bar;
    private Spice.Widgets.Toolbar canvas_bar;
    private Spice.Widgets.Toolbar common_bar;

    public DynamicToolbar (SlideManager slide_manager) {
        manager = slide_manager;

        valign = Gtk.Align.START;

        stack = new Gtk.Stack ();
        stack.set_transition_type (Gtk.StackTransitionType.SLIDE_DOWN);

        get_style_context ().add_class ("toolbar");
        get_style_context ().add_class ("inline-toolbar");

        text_bar = new Spice.Widgets.TextToolbar ();
        shape_bar = new Spice.Widgets.ShapeToolbar ();
        image_bar = new Spice.Widgets.ImageToolbar ();
        canvas_bar = new Spice.Widgets.CanvasToolbar (slide_manager);
        common_bar = new Spice.Widgets.CommonToolbar (slide_manager);

        stack.add_named (text_bar, TEXT);
        stack.add_named (shape_bar, SHAPE);
        stack.add_named (image_bar, IMAGE);
        stack.add_named (canvas_bar, CANVAS);

        this.add (stack);
        this.add (common_bar);

        Spice.Services.HistoryManager.get_instance ().action_called.connect ((i) => {
            item_selected (i);
        });
    }

    public void item_selected (Spice.CanvasItem? item, bool new_item = false) {
        if (item == null) {
            stack.set_visible_child_name (CANVAS);
            canvas_bar.select_item (item, manager.making_new_slide);
        } else if (item is TextItem) {
            stack.set_visible_child_name (TEXT);
            text_bar.select_item (item, new_item);
        } else if (item is ColorItem) {
            stack.set_visible_child_name (SHAPE);
            shape_bar.select_item (item, new_item);
        } else if (item is ImageItem) {
            stack.set_visible_child_name (IMAGE);
            image_bar.select_item (item, new_item);
        }

        common_bar.select_item (item, new_item);
    }
}
