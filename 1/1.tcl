#!/usr/bin/tclsh

proc sum_adjacent _list {
    set _sum        0
    set _last_digit [string index $_list end]
    foreach _number [split $_list ""] {
	if {$_last_digit == $_number} {
	    set _sum [expr $_sum + $_number]
	}
	set _last_digit $_number
    }
    return $_sum;
}

set fp        [open "input" r]
set file_data [read $fp]
close $fp

puts "The anser is: [sum_adjacent $file_data]"
