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

Version:        2.0

Date :          1/27/2015

Description :   Allows the user to do two things:
                1)  Lay an arbitrarily-oriented face or collection of coplanar faces flat
                    on the ground. Use in combination with a manual unfold tool to flatten shapes first.
                2)  Unwrap non-coplanar faces uaing an automatic (random) algorithm and then 
                    lay the resulting set of faces flat on the ground.
                This helps in producing cutouts, as CNC-prep, for texturing, etc.
                
Usage :         Select one or more faces and right-click on them to get the 
                "Flatten faces" menu.

History:        1.0 (2/12/2014):
                - Initial release
                2.0 (1/27/2015):
                - Added functionality to automatically unwrap non-coplanar faces first
                
Issues:         - The unwrapping algorithm doesn't always work automatically. It basically starts at a 
                  random face and tries to line up all faces in a logical pattern. If this doesn't succeed,
                  then it iterates 100 times to get this right. If it still doesn't work, re-try with fewer 
                  faces in your selection. Each run is random, so results can vary between tries.                
                
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
    
    ofaces = Array.new
    faces = Array.new
    
    # Make a collection of all faces in the selection    
    sel.each {|e|
      ofaces.push(e) if e.is_a? Sketchup::Face
    }
    
    # Base everything on the first face
    e = ofaces[0]   
    
    # Check if all selected faces are coplanar
    coplanar = true
    ofaces.each {|f|
      coplanar = false if not f.normal.parallel? e.normal
    }
    
    if coplanar  # Just lay the faces flat without unwrapping
    
      mod.start_operation "Flatten Faces"    
      
      # Copy the original faces array
      faces = ofaces.dup
  
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
    
    else  # Try to unwrap faces first, then lay them flat
    
      # Mention what we will do
      UI.messagebox "Non-coplanar faces selected. I will try to unwrap first and then flatten them. This doesn't always work automatically. Re-try with fewer faces in your selection if you run into problems. Each run is random, so results can vary between tries."
      
      mod.start_operation "Unwrap and Flatten"   
      
      # A few more variables for this
      afaces = Array.new  # Need one more copy for iterations
      max_tries = 100  # Max number of iterations
      n = 0
      
      # Use max. attemps to consider all of the faces
      until (faces.length == ofaces.length or n > max_tries-1)
      
        # Reset arrays for this iteration
        faces = []
        afaces = ofaces.dup  # use dup to make a duplicate here!
        n += 1
        
        # Start with a random face in the set
        lface = afaces[rand(0..afaces.count-1)]
        faces << lface
        afaces.delete lface
        
        # Now walk through all the remaining faces and try to find a path
        for i in 1..afaces.count
        
          nface = nil
          
          # check all edges of a face
          lface.edges.each { |e|
          
            # only do this if two faces are at same edge
            if e.faces.length > 1
              # get tentative new face
              tface = (e.faces - [lface]).first
              # check if it's still available
              if (afaces.index(tface) != nil)
                # add it to the array and use it as the new start face
                nface = tface
                afaces.delete nface
                faces << nface
                lface = nface
              end
            end
            # we have found a face!
            break if (nface != nil)
            
          }      
            
        end  
      
      end
      
      # Catch problems while unwrapping
      begin
      
        # Array for all unwrapped faces
        done = Array.new
        
        # Now iterate through the faces
        (1..faces.length-1).each {|i|
        
          # Find common edge
          cedge = faces[i].edges & faces[i-1].edges
          
          # Get target normal and do the transformation math
          tnormal = faces[i].normal
          onormal = faces[i-1].normal
          rot = tnormal.angle_between onormal
          cr = tnormal.cross onormal
          t = Geom::Transformation.rotation cedge[0].start, cr, -rot
        
          # Add the face to the done faces and flip them flat
          done.push faces[i-1]
          g = ent.add_group(done)
          g.transform! t
          g.explode
        
        }
        
        # Group everything after unwrapping
        done.push faces.last
        d = ent.add_group(done)
        
        # Then rotate the group - if necessary - so that it points up
        # Base on first face in collection
        e = faces[0]
        if !e.normal.parallel? [0,0,1]
          rot = e.normal.angle_between [0,0,1]
          cr = e.normal.cross [0,0,1]
          t1 = Geom::Transformation.rotation d.bounds.center, cr, rot
          d.transform! t1
        end
      
        # Then drop to z=0
        el = d.bounds.center.z
        t2 = Geom::Transformation.translation [0,0,-el]
        d.transform! t2
        
      rescue
        
        UI.messagebox "Problems with automatic unwrapping (used #{n} attempts). Please undo and try again with fewer faces."
        
      end      
      
      # Allow for undo
      mod.commit_operation      
    
    end
  
  end # flatten_face 
  
  
  def self.contains_face
  # Checks if there is at least one face in the selection set
  
    contains = false
    Sketchup.active_model.selection.each{|e|
      contains = true if e.is_a? Sketchup::Face
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
