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

proc run_instr {regsname curname} {
    upvar 1 $regsname regs
    upvar 1 $curname cur
    upvar 1 debug debug
    global muls
    global indata
    set parsed 0
    set instr [lindex $indata $cur]
    if {$debug} { puts $instr }
    if {[regexp {set ([a-z]) ([-0-9]+)} $instr _match reg value]} {
        set parsed 1
        set regs($reg) $value
        if {$debug} {puts "$reg: $regs($reg)"}
    }

    if {[regexp {set ([a-z]) ([a-z])} $instr _match reg regvalue]} {
        set parsed 1
        if {![info exists regs($regvalue)]} {
            set regs($regvalue) 0
        }
        set regs($reg) $regs($regvalue)
        if {$debug} {puts "$reg: from $regvalue: $regs($regvalue)"}
    }

    if {[regexp {sub ([a-z]) ([-0-9]+)} $instr _match reg value]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {$debug} {puts -nonewline "$reg: $regs($reg) - $value = "}
        set regs($reg) [expr $regs($reg) - $value]
        if {$debug} {puts "$regs($reg)"}
    }

    if {[regexp {sub ([a-z]) ([a-z])} $instr _match reg regvalue]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {![info exists regs($regvalue)]} {
            set regs($regvalue) 0
        }
        if {$debug} {puts -nonewline "$reg: $regs($reg) - $regvalue: $regs($regvalue) = "}
        set regs($reg) [expr $regs($reg) - $regs($regvalue)]
        if {$debug} {puts "$regs($reg)"}
    }

    if {[regexp {mul ([a-z]) ([-0-9]+)} $instr _match reg value]} {
        incr muls
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {$debug} {puts -nonewline "$reg: $regs($reg) * $value = "}
        set regs($reg) [expr $regs($reg) * $value]
        if {$debug} {puts "$regs($reg)"}
    }

    if {[regexp {mul ([a-z]) ([a-z])} $instr _match reg regvalue]} {
        incr muls
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {![info exists regs($regvalue)]} {
            set regs($regvalue) 0
        }
        if {$debug} {puts -nonewline "$reg: $regs($reg) * $value = "}
        set regs($reg) [expr $regs($reg) * $regs($regvalue)]
        if {$debug} {puts "$regs($reg)"}
    }

    if {[regexp {jnz ([a-z]) ([-0-9]+)} $instr _match reg value]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {$regs($reg) != 0} {
            set cur [expr $cur + $value - 1]
        }
    }

    if {[regexp {jnz ([a-z]) ([a-z])} $instr _match reg regvalue]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {![info exists regs($regvalue)]} {
            set regs($regvalue) 0
        }
        if {$regs($reg) != 0} {
            set cur [expr $cur + $regs($regvalue) - 1]
        }
    }

    if {[regexp {jnz ([-0-9]) ([-0-9]+)} $instr _match reg value]} {
        set parsed 1
        if {$reg != 0} {
            set cur [expr $cur + $value - 1]
        }
    }

    incr cur

    if {$parsed == 0} {
        puts "Could not parse: $instr"
        exit
    }
}

set debug 0
set muls 0
set cur 0
while {$cur >= 0 && $cur < [llength $indata]} {
    run_instr regs cur
}

puts "Number of muls: $muls"


# Rewritten code from assembler

set start 108100
set stop  125100
set inc   17
set h     0

for {set num $start} {$num <= $stop} {set num [expr $num + 17]} {
    puts "Checking $num"
    for {set e 2} {$e <= [expr isqrt($num)]} {incr e} {
        if {[expr $num % $e] == 0} {
            puts "Found Non-prime"
            incr h
            break
        }
    }
}


puts "Value of reg h: $h"
