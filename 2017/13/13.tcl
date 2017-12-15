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

proc init_firewall {} {
    global firewall
    global indata
    global maxlayer
    set last_layer 0
    foreach data $indata {
	set s [split $data ": "]
	set layer [lindex $s 0]
	set depth [lindex $s 2]

	for {set i $last_layer} {$i < [expr $layer - 1]} {incr i} {
	    lappend firewall 0
	}
	lappend firewall $depth
	set maxlayer $layer
	set last_layer $layer
    }
}

proc calc_score {} {
    global firewall
    global maxlayer
    set score 0
    for {set i 0} {$i <= $maxlayer} {incr i} {
	set value [lindex $firewall $i]
	if {$value} {
	    if {[expr $i % ((2 * ($value - 1)))] == 0} {
		set score [expr $score + ($value * $i)]
	    }
	}
    }
    return $score
}

proc check_caught {offset} {
    global firewall
    global maxlayer
    for {set i 0} {$i <= $maxlayer} {incr i} {
	set value [lindex $firewall $i]
	if {$value} {
	    if {[expr [expr $offset + $i] % ((2 * ($value - 1)))] == 0} {
		return 1
	    }
	}
    }
    return 0
}

init_firewall

puts "Score: [calc_score]"

set delay 0
set score 1
while {$score != 0} {
    incr delay
    set score [check_caught $delay]
}

puts "Delay without getting stuck: $delay"
