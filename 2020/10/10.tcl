#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	#lappend indata [regexp -inline -all -- {\S+} $row]
	lappend indata $row
    }
}

set adapters [lsort -integer $indata]

set jolt 0
foreach adapter $adapters {
    if {$jolt + 1 == $adapter} {
        incr one
    }

    if {$jolt + 3 == $adapter} {
        incr three
    }

    set jolt $adapter
}

incr three

puts "1-jolt ($one) * 3-jolt ($three): [expr $one * $three]"

set outlet 0
set device [expr $jolt + 3]

# Add outlet and my device
lappend adapters $outlet
lappend adapters $device
set adapters [lsort -integer $adapters]

foreach adapter $adapters {
    if {[lsearch $adapters [expr $adapter + 1]] != -1} {
        lappend connections($adapter) [expr $adapter + 1]
    }

    if {[lsearch $adapters [expr $adapter + 2]] != -1} {
        lappend connections($adapter) [expr $adapter + 2]
    }

    if {[lsearch $adapters [expr $adapter + 3]] != -1} {
        lappend connections($adapter) [expr $adapter + 3]
    }
}

proc get_combinations {jolt} {
    upvar 1 connections connections
    upvar 1 device device
    upvar 1 memo memo

    if {[info exists memo($jolt)]} {
        return $memo($jolt)
    }

    if {$jolt == $device} {
        return 1
    }

    if {[info exist connections($jolt)]} {
        foreach connection $connections($jolt) {
            incr total [get_combinations $connection]
        }
        set memo($jolt) $total
        return $total
    } else {
        return 0
    }
}

puts "Total arrangements: [get_combinations $outlet]"
