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

set pos 1
foreach data [split $indata ""] {

    # Go one floor up
    if {$data == "("} {
        incr floor +1
    }

    # Go one floor down
    if {$data == ")"} {
        incr floor -1
    }

    # If we have not been in the basement yet,
    # and we're in the basement set the position
    if {![info exist first] && $floor == -1} {
        set first $pos
    }

    incr pos
}

puts "Final floor: $floor"
puts "Position of first time in basement: $first"
