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

# Parse the requirements
# Result is a list of requirements
# Each requirement is a list of amount and chemical
proc parse_requirements {inputs} {
    foreach input [split $inputs ","] {
        if {[regexp {([0-9]+) ([A-Z]+).*} $input _match amount what]} {
            lappend parsed [list $amount $what]
        }
    }
    return $parsed
}

# Parse the puzzle input and put it into reactions
foreach data $indata {
    if {[regexp {(.*) => ([0-9]+) ([A-Z]+)} $data _match inputs amount output]} {
        set reactions($output) [list $amount [parse_requirements $inputs]]
    }
}

# Recursive calculation for getting an amount of a chemical
proc calc_chemical {get_amount get_chemical} {
    upvar 1 chemicals chemicals
    upvar 1 reactions reactions
    
    if {$get_chemical == "ORE"} {
        incr chemicals(ORE) $get_amount
        return
    }

    while 1 {
        # See if the wanted chemical is available
        set available 0
        if {[info exists chemicals($get_chemical)]} {
            set available $chemicals($get_chemical)

            if {$available >= $get_amount} {
                incr chemicals($get_chemical) -$get_amount
                return
            }
    
        }

        # It was not available, run the reaction <x> times to the the requested amount
        lassign $reactions($get_chemical) result_amount requirements
        set runs [expr int(ceil(double($get_amount - $available) / double($result_amount)))]

        # Get the required chemicals
        foreach requirement $requirements {
            lassign $requirement req_amount req_chemical
            calc_chemical [expr $runs * $req_amount] $req_chemical
        }

        # increment the reaction resulting chemical
        incr chemicals($get_chemical) [expr $runs * $result_amount]
    }
}

# Get one fuel
calc_chemical 1 FUEL
puts "$chemicals(ORE) ORE is needed for 1 FUEL"

# Looping one FUEL at a time to find when we hit the target is slow
# Find the upper limit first (10 digits assumed) and then refine
# the result into the lower digits.
set target 1000000000000
set result []
for {set digit 10} {$digit > 0} {incr digit -1} {
    for {set i 0} {$i <= 9} {incr i} {
        array unset chemicals
        set fuel [string trimleft [join $result ""] 0][expr int($i * pow(10,($digit - 1)))]
        calc_chemical $fuel FUEL

        if {$chemicals(ORE) >= $target} {
            lappend result [expr $i - 1]
            break
        }
    }
}

puts "$target ORE can produce [string trimleft [join $result ""] 0] FUEL"
