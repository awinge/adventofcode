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

foreach instruction $indata {
    set parts [split $instruction]

    set reg   [lindex $parts 0]
    set op    [lindex $parts 1]
    set value [lindex $parts 2]
    set condreg [lindex $parts 4]
    set condop  [lindex $parts 5]
    set condval [lindex $parts 6]

    
    if {![info exists regs($condreg)]} {
	set regs($condreg) 0
    }
    if {[expr $regs($condreg) $condop $condval]} {
	if {![info exists regs($reg)]} {
	    set regs($reg) 0
	}
	
	switch $op {
	    inc { set regs($reg) [expr $regs($reg) + $value] }
	    dec { set regs($reg) [expr $regs($reg) - $value] }
	}

	foreach {key value} [array get regs] {
	    if {![info exists totmax] || $value > $totmax} {
		set totmax $value
	    }
	}
    }
}

foreach {key value} [array get regs] {
    if {![info exists max] || $value > $max} {
	set max $value
    }
}
puts "Maximum value in any register: $max"
puts "Maximum value in any register during execution: $totmax"
