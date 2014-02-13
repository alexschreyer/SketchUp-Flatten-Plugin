=begin

Copyright 2014, Alexander C. Schreyer
All rights reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/flatten-faces-plugin/

Name :          Flatten Faces

Version:        1.0

Date :          2/12/2014

Description :   Allows the user to lay an arbitrarily-oriented face flat
                on the ground. This helps in producing cutouts, as CNC-prep etc.
                Use in combination with an unfold tool to flatten shapes.
                
Usage :         Select one or more faces and right-click on them to get the 
                "Flatten faces" menu.

History:        1.0 (2/12/2014):
                - Initial release
                
TODO List:      

=end


require 'sketchup'


# =========================================


module AS_Flatten

  def self.flatten_face
  # Flattens (into x-y plane) all selected faces in place
  
    mod = Sketchup.active_model
    ent = mod.entities
    sel = mod.selection 
    
    # Make a collection of all faces in the selection
    faces = []
    sel.each {|e|
      faces.push(e) if e.typename == "Face"
    }
    
    # Base everything on the first face
    e = faces[0]   
    
    # Check that all selected faces are coplanar
    coplanar = true
    faces.each {|f|
      coplanar = false if not f.normal.parallel? e.normal
    }
    
    if coplanar
    
      mod.start_operation "Flatten Faces"     
  
      # First create a group of the face(s)
      group = ent.add_group(faces)
    
      # Then rotate the group - if necessary - so that it points up
      # Base on first face in collection
      if !e.normal.parallel? [0,0,1]
        rot = e.normal.angle_between [0,0,1]
        cr = e.normal.cross [0,0,1]
        t1 = Geom::Transformation.rotation group.bounds.center, cr, rot
        group.transform! t1
      end
    
      # Then drop to z=0
      el = group.bounds.center.z
      t2 = Geom::Transformation.translation [0,0,-el]
      group.transform! t2
      
      # Allow for undo
      mod.commit_operation
    
    else
    
      UI.messagebox "Please select only a single face or multiple coplanar faces."
    
    end
  
  end # flatten_face 
  
  
  def self.contains_face
  # Checks if there is at least one face in the selection set
  
    contains = false
    Sketchup.active_model.selection.each{|e|
      contains = true if e.typename == "Face"
    }
    return contains

  end # contains_face
  

end # AS_Flatten


# =========================================


# Load plugin at startup and add menu items to context menu
if !file_loaded?(__FILE__)
  
  # Add to the context menu
  UI.add_context_menu_handler do |menu|
    if( AS_Flatten::contains_face )
      menu.add_item("Flatten Faces") { AS_Flatten::flatten_face }
    end
  end
  
  # Let Ruby know we have loaded this file
  file_loaded(__FILE__)

end # if


# =========================================
