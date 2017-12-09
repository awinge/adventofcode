#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

set total_garbage 0

proc get_garbage_length {input} {
    global total_garbage
    set index 0
    # compensating for the starting '<' which shall not be counted
    set total_garbage [expr $total_garbage - 1] 
    while 1 {
	switch [lindex $input $index] {
	    !  {set index [expr $index + 2]}
	    >  {return [expr $index + 1]}
	    default {
		incr total_garbage
		incr index
	    }
	}
    }
}

# Returns the score and a length of the group scored
proc get_score {input depth} {
    set index 0
    set group_score $depth
    while {$index < [llength $input]} {
	switch [lindex $input $index] {
	    \{ {set subgroup_data [get_score [lrange $input [expr $index + 1] end] [expr $depth + 1]]
		set group_score [expr $group_score + [lindex $subgroup_data 0]]
		set index [expr $index + [lindex $subgroup_data 1]]}

	    \} {#puts "Scored group ($group_score): \{[join [lrange $input 0 $index] ""]"
		return [list $group_score [expr $index + 2]]}

	    !  {set index [expr $index + 2]}

	    <  {set garbage_length [get_garbage_length [lrange $input $index end]]
		set index [expr $index + $garbage_length]}

	    ,  {#set group_score [expr $group_score + $depth]
		incr index}

	    default { incr index }
	    
	}
    }
    return $group_score
}

puts [get_score [split $fd ""] 0]
puts $total_garbage
