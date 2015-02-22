=begin

Copyright 2014-2015, Alexander C. Schreyer
All rights reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/flatten-faces-plugin/

Name :          Unwrap and Flatten Faces

Version:        2.1

Date :          2/22/2015

Description :   Allows the user to do two things:
                1)  Lay an arbitrarily-oriented face or collection of coplanar faces flat
                    on the ground. Use in combination with a manual unfold tool to flatten shapes first.
                2)  Unwrap non-coplanar faces uaing an automatic (random) algorithm and then
                    lay the resulting set of faces flat on the ground.
                This helps in producing cutouts, as CNC-prep, for texturing, etc.

Usage :         Select one or more faces and right-click on them to get the
                "Flatten faces" menu. Or use the "Unwrap and Flatten" menu items in the Tools menu.

History:        1.0 (2/12/2014):
                - Initial release
                2.0 (1/27/2015):
                - Added functionality to automatically unwrap non-coplanar faces first
                2.1 (2/22/2015):
                - Added Tools menu item to remove confusion
                - Added statusbar feedback (important for larger models)
                - Added Help submenu item
                - Code cleanup
                - Fixed SU 8 bug with array.count

Issues:         - The unwrapping algorithm doesn't always work automatically. It basically starts at a
                  random face and tries to line up all faces in a logical pattern. If this doesn't succeed,
                  then it iterates 100 times to get this right. If it still doesn't work, re-try with fewer
                  faces in your selection. Each run is random, so results can vary between tries.

TODO List:

=end


# =========================================


require 'sketchup'
require 'extensions'


# =========================================


as_flatten = SketchupExtension.new "Unwrap and Flatten Faces", "as_flatten/as_flatten.rb"
as_flatten.copyright= 'Copyright 2014-2015 Alexander C. Schreyer'
as_flatten.creator= 'Alexander C. Schreyer, www.alexschreyer.net'
as_flatten.version = '2.1'
as_flatten.description = "Allows the user to automatically unwrap several faces and lay them flat on the ground. This helps in producing cutouts, as CNC-prep, for texturing etc. Can also be used in combination with a manual unfold tool to lay flat shapes on the ground. Usage: Select one or more ungrouped faces and right-click on them to get the 'Flatten faces' menu."
Sketchup.register_extension as_flatten, true


# =========================================
