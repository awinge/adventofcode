#!/usr/bin/tclsh

proc numbers_in_ring _ring_no {
    if {$_ring_no == 1} {
	return 1
    }

    set _ring_side       [expr 2 * $_ring_no - 1]
    set _inner_ring_side [expr 2 * ($_ring_no - 1) - 1]

    return [expr ($_ring_side**2) - ($_inner_ring_side**2)]
}

proc get_ring_manhattan {_ring _index} {
    if {$_ring == 1} {
	return 0
    }

    set _max_manhattan   [expr 2 * ($_ring - 1)]
    set _min_manhattan   [expr ($_ring - 1)]
    set _start_manhattan [expr $_max_manhattan - 1]
    set _manhattan       $_start_manhattan

    if {$_manhattan == $_min_manhattan} {
	set _decr 0
    } else {
	set _decr 1
    }
    
    for {set i 0} {$i < $_index} {incr i} {
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
    return $_manhattan
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

puts "The answer is: [spiral_manhattan [expr $argv -1]]"

