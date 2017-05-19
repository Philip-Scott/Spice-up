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

public abstract class Spice.Widgets.Toolbar : Gtk.Box {
    protected bool init = false;
    protected bool selecting = false;
    protected Spice.CanvasItem? item;

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 12;
        border_width = 6;
    }

    public void select_item (Spice.CanvasItem? item_, bool new_item = false) {
        selecting = true;
        item = item_;
        item_selected (item_, new_item && init);
        selecting = false;
        init = true;
    }

    protected abstract void item_selected (Spice.CanvasItem? item, bool new_item = false);

    public abstract void update_properties ();
}
