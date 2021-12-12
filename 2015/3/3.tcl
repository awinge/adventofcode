#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	#lappend indata [regexp -inline -all -- {\S+} $row]
	lappend indata $row
    }
}

set x 0
set y 0

incr grid($x,$y)

foreach data [split $indata ""] {
    # up
    if {$data == "^"} {
        incr y -1
    }

    # right
    if {$data == ">"} {
        incr x 1
    }

    # down
    if {$data == "v"} {
        incr y 1
    }

    # left
    if {$data == "<"} {
        incr x -1
    }

    incr grid($x,$y)
}

puts "Houses with at least one present: [array size grid]"


array unset grid

set x0 0
set y0 0
set x1 0
set y1 0

incr grid($x0,$y0)
incr grid($x1,$y1)

set turn 0

foreach data [split $indata ""] {
    # up
    if {$data == "^"} {
        incr y${turn} -1
    }

    # right
    if {$data == ">"} {
        incr x${turn} 1
    }

    # down
    if {$data == "v"} {
        incr y${turn} 1
    }

    # left
    if {$data == "<"} {
        incr x${turn} -1
    }

    incr grid([set x${turn}],[set y${turn}])

    set turn [expr ($turn + 1) % 2]
}

puts "Houses with at least one present: [array size grid]"
