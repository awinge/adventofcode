#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    lappend indata $row
}

set total 0
foreach data $indata {
    if {$data != ""} {
        foreach q [split $data ""] {
            set answers($q) 1
        }
    } else {
        set total [expr $total + [array size answers]]
        array unset answers
    }
}
puts "Sum anyone yes: $total"


set total 0
set persons 0
foreach data $indata {
    if {$data != ""} {
        foreach q [split $data ""] {
            if {![info exists answers($q)]} {
                set answers($q) 1
            } else {
                incr answers($q)
            }
        }
        incr persons
    } else {
        foreach {key value} [array get answers] {
            if {$value == $persons} {
                incr total
            }
        }
        array unset answers
        set persons 0
    }
}
puts "Sum everyone yes: $total"
