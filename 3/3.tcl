#!/usr/bin/tclsh

# Calculates the number of numbers in a ring
# Rings are indexed as the center being ring 1
proc numbers_in_ring _ring {
    if {$_ring == 1} {
	return 1
    }

    set _ring_side       [expr 2 * $_ring - 1]
    set _inner_ring_side [expr 2 * ($_ring - 1) - 1]

    return [expr ($_ring_side**2) - ($_inner_ring_side**2)]
}

# Returns a list manhattans of ring number _ring 
proc make_ring_manhattan_list {_ring} {
    set _max_manhattan   [expr 2 * ($_ring - 1)]
    set _min_manhattan   [expr ($_ring - 1)]
    set _start_manhattan [expr $_max_manhattan - 1]
    set _manhattan       $_start_manhattan

    if {$_manhattan == $_min_manhattan} {
	set _decr 0
    } else {
	set _decr 1
    }

    set _list {}
    for {set i 0} {$i < [numbers_in_ring $_ring]} {incr i} {
	lappend _list $_manhattan
	if {$_decr} {
	    set _manhattan [expr $_manhattan - 1]
	    if {$_manhattan == $_min_manhattan} {
		set _decr 0
	    }
	} else {
	    set _manhattan [expr $_manhattan + 1]
	    if {$_manhattan == $_max_manhattan} {
 		set _decr 1
	    }
	}
    }
    return $_list
}

proc get_ring_manhattan {_ring _index} {
    if {$_ring == 1} {
	return 0
    }
    set _list [make_ring_manhattan_list $_ring]
    return [lindex $_list $_index]
}

proc spiral_manhattan _index {
    set _current_ring 1
    while {$_index >= [numbers_in_ring $_current_ring]} {
	set _index [expr $_index - [numbers_in_ring $_current_ring]]
	incr _current_ring
    }
    puts "Ring: $_current_ring"
    puts "Index: $_index"
    return [get_ring_manhattan $_current_ring $_index]
}

proc make_ring_sum_list _ring {
    if {$_ring == 1} {
	return {1}
    }
    if {$_ring == 2} {
	return {1 2 4 5 10 11 23 25}
    }

    set _ring_side       [expr 2 * $_ring - 1]
    set _inner_ring_side [expr 2 * ($_ring - 1) - 1]
    
    set _inner_ring [make_ring_sum_list [expr $_ring - 1]]
    set _current_inner_index 0

    set _return_list {}

    for {set _side 0} {$_side < 4} {incr _side} {
	for {set _side_count 1} {$_side_count < $_ring_side} {incr _side_count} {
	    # Just after a corner
	    if {$_side_count == 1} {
		if {$_side == 0} {
		    lappend _return_list [expr [lindex $_inner_ring 0] +   \
					       [lindex $_inner_ring end]]
		    lappend _return_list [expr [lindex $_inner_ring 0] +   \
					       [lindex $_inner_ring 1] +   \
					       [lindex $_inner_ring end] + \
					       [lindex $_return_list end]]
		    incr _side_count
		    set _current_inner_index 1
		} else {
		    lappend _return_list [expr [lindex $_inner_ring       $_current_inner_index] +      \
					       [lindex $_inner_ring [expr $_current_inner_index + 1]] + \
					       [lindex $_return_list end] +                             \
					       [lindex $_return_list end-1]]
		    incr _current_inner_index
		}
	    # Before a corner
	    } elseif {$_side_count == $_inner_ring_side} {
		if {$_side == 3} {
		    lappend _return_list [expr [lindex $_inner_ring [expr $_current_inner_index - 1]] + \
					       [lindex $_inner_ring       $_current_inner_index] +      \
					       [lindex $_return_list end] +                             \
					       [lindex $_return_list 0]]
		} else {
		    lappend _return_list [expr [lindex $_inner_ring [expr $_current_inner_index - 1]] + \
					       [lindex $_inner_ring       $_current_inner_index] +      \
					       [lindex $_return_list end]]
		}
	    # Corner
	    } elseif {$_side_count > $_inner_ring_side} {
		if {$_side == 3} {
		    lappend _return_list [expr [lindex $_inner_ring [expr $_current_inner_index]] +     \
					       [lindex $_return_list end] +                             \
					       [lindex $_return_list 0]]
		} else {		    
		    lappend _return_list [expr [lindex $_inner_ring [expr $_current_inner_index]] +     \
					       [lindex $_return_list end]]
		}
	    } else {
		lappend _return_list [expr [lindex $_inner_ring [expr $_current_inner_index - 1]] + \
					   [lindex $_inner_ring       $_current_inner_index] +      \
					   [lindex $_inner_ring [expr $_current_inner_index + 1]] + \
					   [lindex $_return_list end]]
		incr _current_inner_index
	    }
	}
    }
    return $_return_list
}

proc spiral_sum_more_than _number {
    set _ring 1
    while {1} {
	foreach _sumnum [make_ring_sum_list $_ring] {
	    if {$_sumnum > $_number} {
		return $_sumnum
	    }
	}
	incr _ring
    }
}

puts "The answer is: [spiral_manhattan [expr $argv -1]]"
puts "The answer for part two is: [spiral_sum_more_than $argv]"
