#!/usr/bin/tclsh

proc find_max_index bank_list {
    set max       0
    set max_index -1
    for {set i 0} {$i < [llength $bank_list]} {incr i} {
	if {[lindex $bank_list $i] > $max} {
	    set max       [lindex $bank_list $i]
	    set max_index $i
	}
    }
    return $max_index
}

proc redistribute {bank_list index} {
    set length [llength $bank_list]
    set redist_blocks [lindex $bank_list $index]
    set bank_list [lreplace $bank_list $index $index 0]
    set replace_index [expr ($index + 1) % $length]
    for {set i 0} {$i < $redist_blocks} {incr i} {
	set current_value [lindex $bank_list $replace_index]
	incr current_value
	set bank_list [lreplace $bank_list $replace_index $replace_index $current_value]
	set replace_index [expr ($replace_index + 1) % $length]
    }
    return $bank_list
}

proc equal_lists {l1 l2} {
    for {set i 0} {$i < [llength $l1]} {incr i} {
	if {[lindex $l1 $i] != [lindex $l2 $i]} {
	    return 0
	}
    }
    return 1
}
    
proc find_loops bank_list {
    set all_bank_lists {}
    set all_bank_lists [lappend all_bank_lists $bank_list]
    set counter 0
    while {1} {
	incr counter
	set max_index [find_max_index $bank_list]
	set bank_list [redistribute $bank_list $max_index]
	foreach l $all_bank_lists {
	    if {[equal_lists $l $bank_list]} {
		puts "Number of iterations: $counter"
		return $bank_list
	    }
	}
	set all_bank_lists [lappend all_bank_lists $bank_list]
    }
}

    
set fp         [open "input" r]
set file_data  [read $fp]
close $fp
set bank_list  [split $file_data]


set bank_list  [find_loops $bank_list]
set bank_list  [find_loops $bank_list]
