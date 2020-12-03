#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	lappend indata $row
    }
}

set x 0
set y 0
foreach data $indata {
    foreach square [split $data ""] {
        set map($x,$y) $square
        incr x
    }
    set width $x
    set x 0
    incr y
}
set depth $y


proc trees {incr_x incr_y} {
    upvar 1 map map
    upvar 1 width width
    upvar 1 depth depth

    set x 0
    set y 0
    while {$y < $depth} {
        if {$map($x,$y) == "#"} {
            incr trees
        }
        incr y $incr_y
        set x [expr ($x + $incr_x) % $width]
    }

    return $trees
}

puts "Number of trees encountered: [trees 3 1]"
puts "Slopes multiplied: [expr [trees 1 1] * [trees 3 1] * [trees 5 1] * [trees 7 1] * [trees 1 2]]"
