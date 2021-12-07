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

set crabs [split $indata ',']

set min_hp [expr min([join $crabs ,])]
set max_hp [expr max([join $crabs ,])]

# Loop through all plausable horizontal positions (hp)
# Get the minimum amount of fuel
# Fuel consumption is the number of steps away from wanted hp
for {set hp $min_hp} {$hp <= $max_hp} {incr hp} {
    set fuel 0
    foreach crab $crabs {
        incr fuel [expr abs($crab - $hp)]
    }

    if {![info exists min_fuel] || $fuel < $min_fuel} {
        set min_fuel $fuel
    }
}

puts "Fuel spent: $min_fuel"

unset min_fuel


# Loop for the second part, new way to calculate fuel consumption
for {set hp 0} {$hp < $max_hp} {incr hp} {
    set fuel 0
    foreach crab $crabs {
        set d [expr abs($crab - $hp)]

        # d * (d + 1) / 2: sum of 1, 2, 3, ..., d
        incr fuel [expr $d * ($d + 1) / 2]
    }

    if {![info exists min_fuel] || $fuel < $min_fuel} {
        set min_fuel $fuel
    }
}

puts "Fuel spent: $min_fuel"
