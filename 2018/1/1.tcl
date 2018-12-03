#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	lappend indata [regexp -inline -all -- {\S+} $row]
    }
}

set frequency  0
set visited(0) 1
set first      1

while 1 {
    # Loop through the frequency changes
    foreach change $indata {
        set frequency [expr $frequency + $change]
        if {[info exists visited($frequency)]} {
            puts "Second answer: $frequency"
            exit
        }
        set visited($frequency) 1
    }

    # If it is the first loop, output the answer
    if {$first == 1} {
        puts "First answer: $frequency"
        set first 0
    }
}
