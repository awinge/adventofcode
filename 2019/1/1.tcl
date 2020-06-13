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

proc get_fuel_from_mass {mass} {
    return [expr int(floor(${mass}/3) - 2)]
}

set total_fuel 0

foreach data $indata {
    set current_fuel [get_fuel_from_mass $data]
    incr total_fuel $current_fuel
}

puts "Total amount of fuel: $total_fuel"

set total_fuel 0
foreach data $indata {
    for {set i [get_fuel_from_mass $data]} {$i > 0} {set i [get_fuel_from_mass $i]} {
        incr total_fuel $i
    }
}

puts "Total amount of fuel including added fuel: $total_fuel"
