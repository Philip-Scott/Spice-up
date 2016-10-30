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

public class Spice.Widgets.ShapeToolbar : Spice.Widgets.Toolbar {
    private Spice.ColorPicker background_color_button;

    construct {
        background_color_button = new Spice.ColorPicker ();
        background_color_button.set_tooltip_text (_("Shape color"));
        background_color_button.gradient = true;

        background_color_button.color_picked.connect ((color) => {
            var action = new Spice.Services.HistoryManager.HistoryAction<ColorItem,string>.item_changed (this.item as ColorItem, "background-color");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_properties ();
        });

        add (background_color_button);
    }

    protected override void item_selected (Spice.CanvasItem? item) {
        background_color_button.color = ((ColorItem) item).background_color;
    }

    public override void update_properties () {
        ColorItem color = (ColorItem) item;
        color.background_color = background_color_button.color;

        item.style ();
    }
}
