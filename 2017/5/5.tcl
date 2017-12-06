#!/usr/bin/tclsh

set fp        [open "input" r]
set file_data [read $fp]
close $fp
set maze_orig [split $file_data "\n"]

set maze $maze_orig

set current_index 0
set counter 0

while {$current_index < [llength $maze]} {
    incr counter
    set jump_value [lindex $maze $current_index]
    set maze [lreplace $maze $current_index $current_index [expr $jump_value + 1]]
    set current_index [expr $current_index + $jump_value]
}

puts "Number of steps: $counter"

set maze $maze_orig
set current_index 0
set counter 0

while {$current_index < [llength $maze]} {
    incr counter
    set jump_value [lindex $maze $current_index]
    if {$jump_value >= 3} {
	set maze [lreplace $maze $current_index $current_index [expr $jump_value - 1]]
    } else {
	set maze [lreplace $maze $current_index $current_index [expr $jump_value + 1]]
    }
	
    set current_index [expr $current_index + $jump_value]
}

puts "Number of steps (part 2): $counter"


