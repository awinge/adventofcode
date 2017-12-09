#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	set indata [lappend indata [regexp -inline -all -- {\S+} $row]]
	set word_length [string length $row]
    }
}

foreach data $indata {
    set word [split $data ""]
    for {set i 0} {$i < [llength $word]} {incr i} {
	set char [lindex $word $i]
	if {![info exist counter${i}($char)]} {
	    set counter${i}($char) 1
	} else {
	    set kalle "counter${i}($char)"
	    set counter${i}($char) [expr $${kalle} + 1]
	}
    }
}

for {set i 0} {$i < $word_length} {incr i} {
    set counter_list {}
    foreach {key value} [array get counter${i}] {
	lappend counter_list [list $key $value]
    }

    set counter_list [lsort -decreasing -index 1 -integer $counter_list]

    lappend most_common_word [lindex [lindex $counter_list 0] 0]
    lappend least_common_word [lindex [lindex $counter_list end] 0]
}

puts "Most common word: [join $most_common_word ""]"
puts "Least common word: [join $least_common_word ""]"
