#!/usr/bin/tclsh

proc sum_offset_match {_list _offset} {
    set _sum 0
    set _list_length [string length $_list]
    set _current_index 0
    foreach _number [split $_list ""] {
	set _offset_index [expr ($_current_index + $_offset) % $_list_length]
	if {$_number == [string index $_list $_offset_index]} {
	    set _sum [expr $_sum + $_number]
	}
	incr _current_index
    }
    return $_sum
}

set fp        [open "input" r]
set file_data [read $fp]
close $fp

puts "The answer is: [sum_offset_match $file_data 1]"

set length [string length $file_data]
puts "The answer for part two is: [sum_offset_match $file_data [expr $length / 2]]"
