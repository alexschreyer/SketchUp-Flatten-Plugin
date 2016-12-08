# =========================================
# Main file for Unwrap and Flatten Faces
# Copyright 2014-2016, Alexander C. Schreyer
# =========================================


require 'sketchup.rb'


# =========================================


module AS_Extensions

  module AS_Flatten
  
  
  # =========================================
  
  
    # Get settings
    @conf = Sketchup.read_default @extname, "confirmation", "show"
    @prompt = Sketchup.read_default @extname, "prompts", "hide"
    @iter = Sketchup.read_default @extname, "iterations", "1000"


  # =========================================
  
  
    def self.rotate_drop( gr )
    # Rotates and drops a group of flattened faces to the ground (z=0)

      # Get first face in group
      fa = gr.entities.grep( Sketchup::Face )[0]
      
      UI.messagebox("Now rotating\nContinue?") if @prompt != "hide"
      
      # Then rotate the group - if necessary - so that it lays flat
      if !fa.normal.parallel?( [0,0,1] )
        rot = fa.normal.angle_between( [0,0,1] )
        cr = fa.normal.cross( [0,0,1] )
        t1 = Geom::Transformation.rotation( gr.bounds.center , cr , rot )
        gr.transform!( t1 )
      end
      
      UI.messagebox("Now dropping to z=0\nContinue?") if @prompt != "hide"

      # Then drop to z=0
      el = gr.bounds.center.z
      t2 = Geom::Transformation.translation( [0,0,-el] )
      gr.transform!( t2 )
    
    end  


  # =========================================


    def self.flatten_face
    # Flattens (into x-y plane) all selected faces

      mod = Sketchup.active_model
      ent = mod.entities
      sel = mod.selection

      # Arrays to hold the faces
      ofaces = Array.new

      # Make a collection of all faces in the selection
      ofaces = sel.grep( Sketchup::Face )

      # Reminder if started from menu item and nothing selected
      if ofaces.length < 1

        UI.messagebox("Select at least one ungrouped face to use this tool.")

      else # Get going

        # Base next steps on the first face
        e = ofaces[0]

        # Check if all selected faces are coplanar
        coplanar = true
        ofaces.each {|f|
          coplanar = false if not f.normal.parallel? e.normal
        }

        if coplanar  # Just group faces without unwrapping, then lay flat

          mod.start_operation("Flatten Faces")

          # Group face(s) and drop
          group = ent.add_group( ofaces )
          rotate_drop( group )

          # Allow for undo
          mod.commit_operation

        else  # Try to unwrap faces first, then lay them flat

          # Mention what we will do
          UI.messagebox("Non-coplanar faces selected. Will try to unwrap first and then flatten them. This doesn't always work automatically. Re-try with fewer faces in your selection if you run into problems. Each run is random, so results can vary between tries.") if @conf != "hide"

          mod.start_operation("Unwrap and Flatten")

          # A few more variables for this
          faces = Array.new
          afaces = Array.new  # Need one more copy for iterations
          max_tries = @iter.to_i # Number of iterations to try
          n = 0

          # Find viable path through set of faces up to max. iterations
          until (faces.length == ofaces.length or n > max_tries-1)

            # Reset arrays for this iteration
            faces = []
            afaces = ofaces.dup  # use dup to make a duplicate here!
            n += 1

            # Give some feedback
            Sketchup.status_text = "Unwrapping | Attempting iteration #{n}"

            # Start with a random face in the set
            lface = afaces[rand(afaces.length-1)]
            faces << lface
            afaces.delete( lface )

            # Now walk through all the remaining faces and try to find a path
            for i in 1..afaces.length

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
                    afaces.delete( nface )
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
              rot = tnormal.angle_between( onormal )
              cr = tnormal.cross( onormal )
              t = Geom::Transformation.rotation( cedge[0].start , cr , -rot )

              # Add the face to the done faces and flip them flat
              done.push faces[i-1]
              g = ent.add_group( done )
              g.transform!( t )
              # Workaround for SU 2017 quirk, face references go away after explode
              done = g.explode.grep( Sketchup::Face )
              
              UI.messagebox( "Face #{i} done\nContinue?" ) if  @prompt  != "hide"

            }

            # Group everything after unwrapping and drop
            done.push faces.last            
            group = ent.add_group( done )            
            rotate_drop( group )

            Sketchup.status_text = "Unwrapping | Done"

          rescue Exception => e  
            
            p e.backtrace.inspect
            Sketchup.status_text = "Unwrapping | Done with problems"
            UI.messagebox("Problems with automatic unwrapping (used #{n} attempts). Please undo and try again with fewer faces. \n\nError: #{e}")

          end

          # Allow for undo
          mod.commit_operation

        end

      end # main routine

    end # def flatten_face


    # =========================================


    def self.contains_face
    # Checks if there is at least one face in the selection set

      contains = false
      Sketchup.active_model.selection.each{|e|
        contains = true if e.is_a? Sketchup::Face
      }
      return contains

    end # contains_face


    # =========================================


    def self.show_help
    # Show the website as an About dialog

      dlg = UI::WebDialog.new('Unwrap and Flatten Faces - Help', true,'AS_Flatten_Help', 1100, 800, 150, 150, true)
      dlg.set_url('http://www.alexschreyer.net/projects/flatten-faces-plugin/')
      dlg.show

    end # show_help


    # =========================================
    
    
    def self.settings
    
      prompts = ["Confirmation dialog","Step prompts","Iterations"]
      defaults = [@conf,@prompt,@iter]
      lists = ["show|hide","show|hide","10|50|100|500|1000|5000"]
      res = UI.inputbox(prompts, defaults, lists, "#{@exttitle} Settings")
      if res
        Sketchup.write_default @extname, "confirmation", @conf = res[0]  
        Sketchup.write_default @extname, "prompts", @prompt = res[1]
        Sketchup.write_default @extname, "iterations", @iter = res[2].to_i
      end
      
    end
    
    
    # =========================================


    # Load plugin at startup and add menu items to context menu
    if !file_loaded?(__FILE__)

      # Add to the tools menu
      tmenu = UI.menu("Tools").add_submenu( @exttitle )
      tmenu.add_item("Flatten Selection") { self.flatten_face }
      tmenu.add_item("Settings") { self.settings }
      tmenu.add_item("Help") { self.show_help }

      # Add to the context menu
      UI.add_context_menu_handler do |menu|
        if( self.contains_face )
          menu.add_item("Flatten Faces") { self.flatten_face }
        end
      end

      # Let Ruby know we have loaded this file
      file_loaded(__FILE__)

    end # if


    # =========================================


  end # module AS_Flatten

end # module AS_Extensions


# =========================================
