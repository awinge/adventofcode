#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	set indata [lappend indata [regexp -inline -all -- {\S+} $row]]
    }
}

proc do_decrypt {indata} {
    set cindex 0
    set decrypt {}
    while {$cindex < [llength $indata]} {
	set start_marker [expr $cindex + [lsearch [lrange $indata $cindex end] "("]]
	if {$start_marker < $cindex} {
	    set decrypt [concat $decrypt [lrange $indata $cindex end]]
	    break
	}

	set end_marker [expr $start_marker + [lsearch [lrange $indata $start_marker end] ")"]]

	set marker [lrange $indata $start_marker $end_marker]

	set marker [join [lrange $marker 1 end-1] ""]
	set marker [split $marker "x"]
    
	set marker_length [lindex $marker 0]
	set marker_reps   [lindex $marker 1]

	set seq [lrange $indata [expr $end_marker + 1] [expr $end_marker + $marker_length]]

	set decrypt [concat $decrypt [lrange $indata $cindex [expr $start_marker - 1]]]

	for {set i 0} {$i < $marker_reps} {incr i} {
	    set decrypt [concat $decrypt $seq]
	}

	set cindex [expr $end_marker + $marker_length + 1]

    }
    return $decrypt
}

proc do_decrypt_count {indata} {
    set decrypt 0

    set start_marker [lsearch $indata "("]
    if {$start_marker == -1} {
	return [llength $indata]
    }

    set end_marker [expr $start_marker + [lsearch [lrange $indata $start_marker end] ")"]]
    set marker [lrange $indata $start_marker $end_marker]

    set marker [join [lrange $marker 1 end-1] ""]
    set marker [split $marker "x"]
    
    set marker_length [lindex $marker 0]
    set marker_reps   [lindex $marker 1]

    set seq [lrange $indata [expr $end_marker + 1] [expr $end_marker + $marker_length]]

    return [expr $start_marker + \
		($marker_reps * [do_decrypt_count $seq]) + \
		[do_decrypt_count [lrange $indata [expr $end_marker + $marker_length + 1] end]]]
}

set indata [split $indata ""]

set decrypt [do_decrypt $indata]

puts "Length of decrypt: [llength $decrypt]"

puts "Length of decrypt: [do_decrypt_count $indata]"




	     
