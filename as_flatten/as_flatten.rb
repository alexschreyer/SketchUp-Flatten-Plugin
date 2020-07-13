# =========================================
# Main file for Unwrap and Flatten Faces
# Copyright 2014-2017, Alexander C. Schreyer
# =========================================


require 'sketchup.rb'


# =========================================


module AS_Extensions

  module AS_Flatten
  
  
  # =========================================

 
    # Get settings
    @conf = Sketchup.read_default @extname, "confirmation", "show"
    @color = Sketchup.read_default @extname, "colorize", "no"
    @prompt = Sketchup.read_default @extname, "prompts", "hide"
    @iter = Sketchup.read_default @extname, "iterations", "1000"
    @axis = Sketchup.read_default @extname, "axis", "Z_AXIS"
    
    # Define some random colors and an index
    @c = []
    50.times {
      @c << Sketchup::Color.new(rand(70..230), rand(70..230), rand(70..230))
    }
    @c_i = 0


  # =========================================
  
  
    def self.rotate_drop( gr )
    # Rotates and drops a group of flattened faces to the ground (z=0)

      # Get first face in group
      fa = gr.entities.grep( Sketchup::Face )[0]
      norm = fa.normal.transform!( gr.transformation )
      
      UI.messagebox("Now rotating\nContinue?") if @prompt == "show"
            
      # Then rotate the group - if necessary - so that it lays flat
      if !norm.parallel?( Object.const_get(@axis) )
        rot = norm.angle_between( Object.const_get(@axis) )
        cr = norm.cross( Object.const_get(@axis) )
        t1 = Geom::Transformation.rotation( gr.bounds.center , cr , rot )
        gr.transform!( t1 )
      end
      
      UI.messagebox("Now dropping to z=0\nContinue?") if @prompt == "show"

      # Then drop to zero
      cen = gr.bounds.center
      case @axis
        when "X_AXIS"
          t2 = Geom::Transformation.translation( [-cen.x,0,0] )
        when "Y_AXIS"
          t2 = Geom::Transformation.translation( [0,-cen.y,0] )          
        else
          t2 = Geom::Transformation.translation( [0,0,-cen.z] )
      end
      gr.transform!( t2 )
    
    end  


  # =========================================
  
  
    def self.flatten_faces
    # Flattens (into x-y plane) all selected faces (without distortions!)

      mod = Sketchup.active_model
      ent = mod.entities
      sel = mod.selection

      # Arrays to hold the faces
      ofaces = Array.new

      # Make a collection of all faces in the selection
      ofaces = sel.grep( Sketchup::Face )
      startnum = ofaces.length

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
          
          # Colorize original faces if desired
          ofaces.each{ |f| f.material = @c[@c_i] if f.is_a? Sketchup::Face } if @color == "yes"

          # Group face(s) and drop
          g = ent.add_group()
          g.transformation = Geom::Transformation.new( e.edges[0].vertices[0].position , e.normal )
          g2 = ent.add_group( ofaces )
          g3 = g.entities.add_instance( g2.definition , g.transformation.invert!*g2.transformation )
          g2.explode
          g3.explode  
          rotate_drop( g )
                      
          # Colorize flattened faces if desired
          g.entities.each{ |f| f.material = @c[@c_i] if f.is_a? Sketchup::Face } if @color == "yes"
          @c_i = rand( @c.length )           

          # Allow for undo
          mod.commit_operation

        else  # Unwrap faces first, then lay them flat

          # Mention what we will do
          UI.messagebox("Non-coplanar faces selected. Will try to unwrap first and then flatten them. This doesn't always work automatically. Re-try with fewer faces in your selection if you run into problems. Each run is random, so results can vary between tries.") if @conf == "show"

          mod.start_operation("Unwrap and Flatten Faces")
          
          # Colorize original faces if desired
          ofaces.each{ |f| f.material = @c[@c_i] if f.is_a? Sketchup::Face } if @color == "yes"

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

          # Now do the actual unwrapping
          
          begin # Catch problems while unwrapping

            # Group for all unwrapped faces
            g = ent.add_group
            g.transformation = Geom::Transformation.new( faces[0].edges[0].vertices[0].position , faces[0].normal )

            # Now iterate through the faces
            (1..faces.length-1).each {|i|

              # Find common edge
              cedge = faces[i].edges & faces[i-1].edges

              # Get target normal and do the transformation math
              tnormal = faces[i].normal
              onormal = faces[i-1].normal
              rot = tnormal.angle_between( onormal )
              cr = tnormal.cross( onormal )
              # Can't do this if faces are coplanar, so add if
              t1 = Geom::Transformation.rotation( cedge[0].start , cr , -rot ) if rot != 0.0
              
              # Add the face to the done group             
              g2 = ent.add_group( faces[i-1] )
              g3 = g.entities.add_instance( g2.definition , g.transformation.invert!*g2.transformation )              
              g2.explode
              g3.explode             
              
              # Then rotate complete group to next face  
              g.transform!( t1 ) if rot != 0.0
              
              UI.messagebox( "Face #{i} done\nContinue?" ) if @prompt == "show"

            }
            
            # Add the last face to the done group             
            g2 = ent.add_group( faces[faces.length-1] )
            g3 = g.entities.add_instance( g2.definition , g.transformation.invert!*g2.transformation )
            g2.explode
            g3.explode    
            UI.messagebox( "Face #{faces.length} done\nContinue?" ) if @prompt == "show"

            # Rotate after unwrapping and drop   
            endnum = g.entities.grep( Sketchup::Face ).length
            rotate_drop( g )
                            
            # Colorize flattened faces if desired
            g.entities.each{ |f| f.material = @c[@c_i] if f.is_a? Sketchup::Face } if @color == "yes"
            @c_i = rand( @c.length ) 
            
            msg = "#{endnum} out of #{startnum} selected faces unwrapped. "
            msg += "Automatic unwrapping is not possible. Select fewer faces (or increase iterations in settings). " if endnum < startnum
            msg += "Unwrapping yielded overlapping faces. Select fewer faces (unwrap in segments) for a better result. " if endnum > startnum
            msg += "\n\nExplode result and run tool again if faces are not on ground."
            UI.messagebox(msg) if @conf == "show" or endnum != startnum
            if endnum == startnum
              Sketchup.status_text = "Unwrapping | Done" 
            else
              Sketchup.status_text = "Unwrapping | Done with problems" 
            end

          rescue Exception => e  
            
            p e.backtrace.inspect
            Sketchup.status_text = "Unwrapping | Done with problems"
            UI.messagebox("Problems with automatic unwrapping (used #{n} attempts). Please undo and try again with fewer faces. \n\nError: #{e}")

          end

          # Allow for undo
          mod.commit_operation

        end

      end # main routine

    end # def flatten_faces
    
    
    # =========================================


    def self.smash_faces
    # Smashes (projects) the selected faces onto a plane (with distortions!)

      mod = Sketchup.active_model
      ent = mod.entities
      sel = mod.selection

      # Array to hold the faces
      ofaces = Array.new

      # Make a collection of all faces in the selection
      ofaces = sel.grep( Sketchup::Face )    
      
      # Reminder if started from menu item and nothing selected
      if ofaces.length < 1

        UI.messagebox("Select at least one ungrouped face to use this tool.")

      else # Get going      
      
        Sketchup.status_text = "Smashing | Working..."
        
        mod.start_operation("Smashing Faces")
        
        # Colorize original faces if desired
        ofaces.each{ |f| f.material = @c[@c_i] if f.is_a? Sketchup::Face } if @color == "yes"
      
        # Group for result and plane
        g = ent.add_group
        plane = [ ORIGIN , Object.const_get(@axis) ]
        
        # Now smash them (by copying)
        ofaces.each { |f|
          begin  # Catch double vertices error
            g.entities.add_face( f.vertices.map{ |i| i.position.project_to_plane( plane ) } )
          rescue
            p "Double vertices ignored"
          end
        }      

        # Reverse any face's direction if needed
        faces = g.entities.grep( Sketchup::Face ) 
        faces.each { |f| f.reverse! if !f.normal.samedirection?( Object.const_get(@axis) ) }
        
        # Colorize flattened faces if desired
        g.entities.each{ |f| f.material = @c[@c_i] if f.is_a? Sketchup::Face } if @color == "yes"
        @c_i = rand( @c.length ) 
        
        # Allow for undo
        mod.commit_operation
        
        Sketchup.status_text = "Smashing | Done"
        
      end

    end # smash_faces   


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
    
    
    def self.show_url( title , url )
    # Show website either as a WebDialog or HtmlDialog
    
      if Sketchup.version.to_f < 17 then   # Use old dialog
        @dlg = UI::WebDialog.new( title , true ,
          title.gsub(/\s+/, "_") , 1000 , 600 , 100 , 100 , true);
        @dlg.navigation_buttons_enabled = false
        @dlg.set_url( url )
        @dlg.show      
      else   #Use new dialog
        @dlg = UI::HtmlDialog.new( { :dialog_title => title, :width => 1000, :height => 600,
          :style => UI::HtmlDialog::STYLE_DIALOG, :preferences_key => title.gsub(/\s+/, "_") } )
        @dlg.set_url( url )
        @dlg.show
        @dlg.center
      end  
    
    end  

    def self.show_help
    # Show the website as an About dialog
    
      show_url( "#{@exttitle} - Help" , 'https://www.alexschreyer.net/projects/flatten-faces-plugin/' )

    end # show_help


    # =========================================
    
    
    def self.settings
    
      prompts = ["Flatten normal to " , "Colorize ", "Iterations " , "Confirmation dialogs " , "Step prompts "]
      defaults = [@axis , @color, @iter , @conf , @prompt]
      lists = ["X_AXIS|Y_AXIS|Z_AXIS" , "yes|no", "10|50|100|500|1000|5000|10000" , "show|hide" , "show|hide"]
      res = UI.inputbox( prompts , defaults , lists , "#{@exttitle} - Settings")
      if res
        Sketchup.write_default @extname, "axis", @axis = res[0]
        Sketchup.write_default @extname, "colorize", @color = res[1]
        Sketchup.write_default @extname, "iterations", @iter = res[2].to_i
        Sketchup.write_default @extname, "confirmation", @conf = res[3]  
        Sketchup.write_default @extname, "prompts", @prompt = res[4]
      end
      
    end
    
    
    # =========================================


    # Load plugin at startup and add menu items to context menu
    if !file_loaded?(__FILE__)

      # Add to the tools menu
      tmenu = UI.menu("Tools").add_submenu( @exttitle )
      tmenu.add_item("Unwrap and Flatten") { self.flatten_faces }
      tmenu.add_item("Smash (project)") { self.smash_faces }
      tmenu.add_item("Settings") { self.settings }
      tmenu.add_item("Help") { self.show_help }

      # Add to the context menu
      UI.add_context_menu_handler do |menu|
        if( self.contains_face )
          sub = menu.add_submenu( @exttitle )
          sub.add_item("Unwrap and Flatten") { self.flatten_faces }
          sub.add_item("Smash (project)") { self.smash_faces }
        end
      end

      # Let Ruby know we have loaded this file
      file_loaded(__FILE__)

    end # if


    # =========================================


  end # module AS_Flatten

end # module AS_Extensions


# =========================================
