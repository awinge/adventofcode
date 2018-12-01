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

set result 0
set visited(0) 1
set first 1

while 1 {
    foreach data $indata {
        set result [expr $result + $data]
        if {[info exists visited($result)]} {
            puts "Second answer: $result"
            exit
        }
        set visited($result) 1
    }
    if {$first == 1} {
        puts "First answer: $result"
        set first 0
    }
}
