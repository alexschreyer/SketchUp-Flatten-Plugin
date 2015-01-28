# Loader for as_flatten/as_flatten.rb

require 'sketchup'
require 'extensions'

as_flatten = SketchupExtension.new "Unwrap and Flatten Faces", "as_flatten/as_flatten.rb"
as_flatten.copyright= 'Copyright 2014-2015 Alexander C. Schreyer'
as_flatten.creator= 'Alexander C. Schreyer, www.alexschreyer.net'
as_flatten.version = '2.0'
as_flatten.description = "Allows the user to automatically unwrap several faces and lay them flat on the ground. This helps in producing cutouts, as CNC-prep, for texturing etc. Can also be used in combination with a manual unfold tool to lay flat shapes on the ground. Usage: Select one or more ungrouped faces and right-click on them to get the 'Flatten faces' menu."
Sketchup.register_extension as_flatten, true
