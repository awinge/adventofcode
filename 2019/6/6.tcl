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

# Build the map
foreach data $indata {
    if {![regexp {([A-Z0-9]+)\)([A-Z0-9]+)} $data _match base orbiter]} {
        puts "Regexp fail for $data"
        exit
    }

    set map($orbiter) [list 0 0 $base]
}

# Procedure to get the number of orbits for an object
proc get_orbits {object} {
    upvar 1 map map

    if {$object == "COM"} {
        return 0
    } else {
        return [expr 1 + [get_orbits [lindex $map($object) 2]]]
    }
}

set total_orbits 0
foreach {object information} [array get map] {
    incr total_orbits [get_orbits $object]
}

puts "Total orbits: $total_orbits"

# Proc to set jumps in the information
proc populate_jumps {index object} {
    upvar 1 map map

    set transfers 0
    while 1 {
        set information $map($object)
        set information [lreplace $information $index $index $transfers]
        set map($object) $information
        incr transfers

        if {[lindex $information 2] == "COM"} {
            break
        } else {
            set object [lindex $information 2]
        }
    }
}

populate_jumps 0 "YOU"
populate_jumps 1 "SAN"

foreach {object information} [array get map] {
    set you_transfers [lindex $information 0]
    set san_transfers [lindex $information 1]
    set transfers [expr $you_transfers + $san_transfers - 2]
    if {$you_transfers != 0 && $san_transfers != 0} {
        if {![info exists least_transfers] || $transfers < $least_transfers} {
            set least_transfers $transfers
        }
    }
}
puts "Least transfers: $least_transfers"
