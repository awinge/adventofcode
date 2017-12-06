#!/usr/bin/tclsh

proc largest_smallest_diff _row {
    set _word_list [regexp -inline -all -- {\S+} $_row]
    foreach _number [split $_word_list] {
	if {![info exist _smallest] || $_number < $_smallest} {
	    set _smallest $_number
	}
	if {![info exist _largest] || $_number > $_largest} {
	    set _largest $_number
	}
    }
    return [expr $_largest - $_smallest]
}

proc even_divider _row {
    set _word_list [regexp -inline -all -- {\S+} $_row]
    set _split_list [split $_word_list]
    for {set i 0} {$i < [llength $_split_list]} {incr i} {
	for {set j [expr $i + 1]} {$j < [llength $_split_list]} {incr j} {
	    set _first_number [lindex $_split_list $i]
	    set _second_number [lindex $_split_list $j]

	    if { [expr $_first_number % $_second_number] == 0} {
		return [expr $_first_number / $_second_number]
	    }
	    if { [expr $_second_number % $_first_number] == 0} {
		return [expr $_second_number / $_first_number]
	    }
	}
    }
    exit(1)
}

set fp        [open "input" r]
set file_data [read $fp]
close $fp

set rows [split $file_data "\n"]

set diff_sum 0
set div_sum 0
foreach row $rows {
    set diff_sum [expr $diff_sum + [largest_smallest_diff $row]]
    set div_sum [expr $div_sum + [even_divider $row]]
}

puts "The answer is: $diff_sum"
puts "The answer to part two is: $div_sum"
