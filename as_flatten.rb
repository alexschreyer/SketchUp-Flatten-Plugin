=begin

Copyright 2014-2016, Alexander C. Schreyer
All rights reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/flatten-faces-plugin/

Name :          Unwrap and Flatten Faces

Version:        2.2

Date :          12/9/2016

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
                2.2 (12/9/2016):
                - Fixed loader code
                - Code cleanup
                - Fixed problem with SU 2017
                - New settings: show/hide dialogs, set iterations, target plane
                - Better unwrapping algorithm, handles larger items now
                - End statistics and feedback added

Issues:         - The unwrapping algorithm doesn't always work automatically. It basically starts at a
                  random face and tries to line up all faces in a logical pattern. If this doesn't succeed,
                  then it iterates 1000 times to get this right. If it still doesn't work, re-try with fewer
                  faces in your selection. Each run is random, so results can vary between tries.

TODO List:

=end


# ========================


require 'sketchup.rb'
require 'extensions.rb'


# ========================


module AS_Extensions

  module AS_Flatten
  
    @extversion           = "2.2"
    @exttitle             = "Unwrap and Flatten Faces"
    @extname              = "as_flatten"
    
    @extdir = File.dirname(__FILE__)
    @extdir.force_encoding('UTF-8') if @extdir.respond_to?(:force_encoding)
    
    loader = File.join( @extdir , @extname , "as_flatten.rb" )
   
    extension             = SketchupExtension.new( @exttitle , loader )
    extension.copyright   = "Copyright 2014-#{Time.now.year} Alexander C. Schreyer"
    extension.creator     = "Alexander C. Schreyer, www.alexschreyer.net"
    extension.version     = @extversion
    extension.description = "Allows the user to automatically unwrap several selected faces and lay them flat on the ground. This helps in producing cutouts, as CNC-prep, for texturing etc. Can also be used in combination with a manual unfold tool to lay flat shapes on the ground. Usage: Select one or more ungrouped faces and right-click on them to get the 'Flatten faces' menu."
    
    Sketchup.register_extension( extension , true )
         
  end  # module AS_Flatten
  
end  # module AS_Extensions


# ========================
