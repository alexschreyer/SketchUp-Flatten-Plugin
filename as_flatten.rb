# Loader for as_flatten/as_flatten.rb

require 'sketchup'
require 'extensions'

as_flatten = SketchupExtension.new "Flatten Face", "as_flatten/as_flatten.rb"
as_flatten.copyright= 'Copyright 2014 Alexander C. Schreyer'
as_flatten.creator= 'Alexander C. Schreyer, www.alexschreyer.net'
as_flatten.version = '1.0'
as_flatten.description = "Allows the user to lay an arbitrarily-oriented face flat on the ground. This helps in producing cutouts, as CNC-prep etc. Use in combination with an unfold tool to flatten shapes. Usage: Select one or more faces and right-click on them to get the 'Flatten faces' menu."
Sketchup.register_extension as_flatten, true