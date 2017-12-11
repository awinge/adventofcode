#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	set indata [lappend indata [regexp -inline -all -- {\S+} $row]]
    }
}

set xpos 0
set ypos 0
set max 0
foreach data [split $indata ","] {
    switch $data {
	n  {set xpos [expr $xpos + 0]
	    set ypos [expr $ypos + 1]}
	ne {set xpos [expr $xpos + 1]
	    set ypos [expr $ypos + 1]}
	e  {set xpos [expr $xpos + 1]
	    set ypos [expr $ypos + 0]}
	se {set xpos [expr $xpos + 1]
	    set ypos [expr $ypos - 1]}
	s  {set xpos [expr $xpos + 0]
	    set ypos [expr $ypos - 1]}
	sw {set xpos [expr $xpos - 1]
	    set ypos [expr $ypos - 1]}
	w  {set xpos [expr $xpos - 1]
	    set ypos [expr $ypos + 0]}
	nw {set xpos [expr $xpos - 1]
	    set ypos [expr $ypos + 1]}
    }
    set max [expr max(abs($xpos), abs($ypos), $max)]
}

puts "Steps from program: [expr max($xpos,$ypos)]"

puts "Max steps away: $max"
