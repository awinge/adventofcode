#!/usr/bin/tclsh

proc step {length} {
    global heading_index
    global heading
    global xpos
    global ypos

    for {set i 0} {$i < $length} {incr i} {
	switch [lindex $heading $heading_index] {
	    N { set ypos [expr $ypos + 1] }
	    E { set xpos [expr $xpos + 1] }
	    S { set ypos [expr $ypos - 1] }
	    W { set xpos [expr $xpos - 1] }
	}
	visit
    }
}

proc turn_left {} {
    global heading_index
    global heading
    set heading_index [expr ($heading_index + 4 - 1) % [llength $heading]]
}

proc turn_right {} {
    global heading_index
    global heading
    set heading_index [expr ($heading_index + 1) % [llength $heading]]
}

proc visit {} {
    global dual_visit
    global xpos
    global ypos
    global visits

    if {!$dual_visit} {
	if {[lsearch $visits [list $xpos $ypos]] >= 0} {
	    puts "First dual visit:"
	    puts "X: $xpos"
	    puts "Y: $ypos"
	    puts "Steps away: [expr abs($xpos) + abs($ypos)]"
	    set dual_visit 1
	}
	set visits [lappend visits [list $xpos $ypos]]
    }
}

set heading {N E S W}
set heading_index 0

set xpos 0
set ypos 0



set fp [open "input" r]
set fd [read $fp]
close $fp

set visits {{0 0}}
set dual_visit 0

foreach step [split $fd ","] {
    incr count
    set step [string trimleft $step]
    set length [string range $step 1 end]
    set turn [string index $step 0]

    switch $turn {
	R { turn_right }
	L { turn_left }
    }
    step $length
}

puts ""
puts "Ending at:"
puts "X: $xpos"
puts "Y: $ypos"

puts "Steps away: [expr abs($xpos) + abs($ypos)]"
