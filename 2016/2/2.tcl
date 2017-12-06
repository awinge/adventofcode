#!/usr/bin/tclsh

set fp [open "input" r]
set fd [read $fp]
close $fp


set keypad {{1 2 3} \
	    {4 5 6} \
            {7 8 9}}

set keypad2 {{"" "" 1 "" ""} \
	     {""  2 3 4  ""} \
	     {  5 6 7 8 9  } \
	     {""  A B C  ""} \
	     {"" "" D "" ""}}

set xpos 1
set ypos 1

puts -nonewline "First part code: "
foreach row [split $fd "\n"] {
    foreach instr [split $row ""] {
	switch $instr {
	    U { if {[lindex [lindex $keypad [expr $ypos - 1]] $xpos] != ""} {set ypos [expr $ypos - 1]}}
	    D { if {[lindex [lindex $keypad [expr $ypos + 1]] $xpos] != ""} {set ypos [expr $ypos + 1]}}
	    R { if {[lindex [lindex $keypad $ypos] [expr $xpos + 1]] != ""} {set xpos [expr $xpos + 1]}}
	    L { if {[lindex [lindex $keypad $ypos] [expr $xpos - 1]] != ""} {set xpos [expr $xpos - 1]}}
	}
    }

    puts -nonewline [lindex [lindex $keypad $ypos] $xpos]
}
puts ""

set xpos 0
set ypos 2

puts -nonewline "Second part code: "
foreach row [split $fd "\n"] {
    foreach instr [split $row ""] {
	switch $instr {
	    U { if {[lindex [lindex $keypad2 [expr $ypos - 1]] $xpos] != ""} {set ypos [expr $ypos - 1]}}
	    D { if {[lindex [lindex $keypad2 [expr $ypos + 1]] $xpos] != ""} {set ypos [expr $ypos + 1]}}
	    R { if {[lindex [lindex $keypad2 $ypos] [expr $xpos + 1]] != ""} {set xpos [expr $xpos + 1]}}
	    L { if {[lindex [lindex $keypad2 $ypos] [expr $xpos - 1]] != ""} {set xpos [expr $xpos - 1]}}
	}
    }

    puts -nonewline [lindex [lindex $keypad2 $ypos] $xpos]
}
puts ""
