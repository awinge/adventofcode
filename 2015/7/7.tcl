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

# Proc for getting the value of a wire.
# It has the option to override a wire with a value
proc get_value {get_wire override override_value} {
    global indata

    # Loop until the wire gets a value
    while {![info exist wires($get_wire)]} {

        # Loop all instructions
        foreach data $indata {
            if {[regexp {^([0-9]*) -> ([a-z]*$)} $data match value wire]} {
                set wires($wire) $value
                continue
            }

            if {[regexp {^([a-z]*) -> ([a-z]*$)} $data match wire res]} {
                if {[info exist wires($wire)]} {
                    set wires($res) $wires($wire)
                }
                continue
            }

            if {[regexp {^NOT ([a-z]*) -> ([a-z]*$)} $data match wire res]} {
                if {[info exist wires($wire)]} {
                    set wires($res) [expr $wires($wire) ^ 65535]
                }
                continue
            }

            if {[regexp {^([a-z]*) AND ([a-z]*) -> ([a-z]*)$} $data match op1 op2 res]} {
                if {[info exist wires($op1)] && [info exist wires($op2)]} {
                    set wires($res) [expr $wires($op1) & $wires($op2)]
                }
                continue
            }

            if {[regexp {^([0-9]*) AND ([a-z]*) -> ([a-z]*)$} $data match value op res]} {
                if {[info exist wires($op)]} {
                    set wires($res) [expr $value & $wires($op)]
                }
                continue
            }


            if {[regexp {^([a-z]*) OR ([a-z]*) -> ([a-z]*)$} $data match op1 op2 res]} {
                if {[info exist wires($op1)] && [info exist wires($op2)]} {
                    set wires($res) [expr $wires($op1) | $wires($op2)]
                }
                continue
            }

            if {[regexp {^([a-z]*) RSHIFT ([0-9]*) -> ([a-z]*)$} $data match op value res]} {
                if {[info exist wires($op)]} {
                    set wires($res) [expr $wires($op) >> $value]
                }
                continue
            }

            if {[regexp {^([a-z]*) LSHIFT ([0-9]*) -> ([a-z]*)$} $data match op value res]} {
                if {[info exist wires($op)]} {
                    set wires($res) [expr $wires($op) << $value]
                }
                continue
            }

            puts "Unparsed: $data"
            exit
        }

        # If override set the override value
        if {$override != ""} {
            set wires($override) $override_value
        }
    }

    return $wires($get_wire)
}

set a [get_value a "" 0]
puts "Value of a: $a"

set a [get_value a b $a]
puts "Value of a: $a"
