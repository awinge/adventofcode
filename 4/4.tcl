#!/usr/bin/tclsh

proc check_valid _string {
    set no_words        [llength [split $_string]]
    set no_unique_words [llength [lsort -unique [split $_string]]]
    if { $no_words == $no_unique_words } {
	return 1
    } else {
	return 0
    }
}    

set fp        [open "input" r]
set file_data [read $fp]
close $fp

set rows [split $file_data "\n"]

set valid   0
set invalid 0
foreach row $rows {
    if { [check_valid $row] } {
	incr valid
    } else {
	incr invalid
    }
}

puts "Valid: $valid"
puts "Invalid: $invalid"

set valid   0
set invalid 0
foreach row $rows {
    set new_row {}
    foreach word [split $row] {
	lappend new_row [join [lsort [split $word ""]] ""]
    }
    if { [check_valid $new_row] } {
	incr valid
    } else {
	incr invalid
    }
}
puts ""
puts "Valid (part 2): $valid"
puts "Invalid (part 2): $invalid"

