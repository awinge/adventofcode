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
    foreach data $indata {
	set s [split $data ": "]
	set layer [lindex $s 0]
	set depth [lindex $s 2]
	
	set firewall($layer) [list 0 $depth 1]
	set maxlayer $layer
    }
}

proc firewall_move {} {
    global firewall
    foreach {key value} [array get firewall] {
	set cur [lindex $value 0]
	set depth [lindex $value 1]
	set dir [lindex $value 2]
	
	set cur [expr $cur + $dir]
	if {$cur >= [expr $depth - 1] || $cur == 0} {
	    if {$dir == 1} {
		set dir -1
	    } else {
		set dir 1
	    }
	}
	set firewall($key) [list $cur $depth $dir]
    }
}

proc calc_score {} {
    global firewall
    global maxlayer
    set score 0
    for {set i 0} {$i <= $maxlayer} {incr i} {
	if {[info exists firewall($i)]} {
	    set value $firewall($i)
	    if {[lindex $value 0] == 0} {
		set score [expr $score + ([lindex $value 1] * $i)]
	    }
	}
	firewall_move
    }
    return $score
}

proc check_caught {} {
    global firewall
    global maxlayer
    for {set i 0} {$i <= $maxlayer} {incr i} {
	if {[info exists firewall($i)]} {
	    set value $firewall($i)
	    if {[lindex $value 0] == 0} {
		return 1
	    }
	}
	firewall_move
    }
    return 0
}

init_firewall
array set blank_firewall [array get firewall]
puts "Score: [calc_score]"

set delay 0
set score 1
while {$score != 0} {
    array set firewall [array get blank_firewall]
    firewall_move
    array set blank_firewall [array get firewall]
    incr delay
    set score [check_caught]
}

puts "Delay without getting stuck: $delay"
