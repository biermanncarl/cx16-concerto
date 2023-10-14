Panels are rectangular areas on the screen that contain basic GUI elements
like listboxes, checkboxes etc.
They behave a bit like windows.
The look and behavior of all panels are hard coded.
However, panels can be made visible/invisible individually, and also their order can be changed.
The order affects which panels appear on top and thus also receive mouse events first.
This is used to be able to dynamically swap out parts of the GUI, or do things like popup menus.
The tool for that is a "panel stack" that defines which panels are shown in which order.

Each panel has multiple byte strings hard coded. Those byte strings define elements shown on the GUI.
  * one string that defines all interactive GUI components, such as checkboxes, listboxes etc.
    It is often called "comps", "component string" or something similar.
    In many subroutines, this component string is given as a zero page pointer together with an offset.
    Those component strings can inherently only be 256 bytes or shorter.
  * one string that defines all static labels displaying text. Those are not interactive.
    It is often called "captions" or something similar.
    It too can only be 256 bytes or shorter. However, this doesn't include the captions themselves,
    but only pointers to them.
Also, some crucial data like position and size and the addresses of aforementioned data blocks are
stored in arrays that can be accessed via the panel's index.

The data blocks that contain the data about the GUI components are partially regarded as constant,
and partially as variable.
Technically, everything about a component could be changed at runtime. However, e.g. for drag edits,
only the shown value and the display state (fine or coarse) are intended to be changed at runtime.

