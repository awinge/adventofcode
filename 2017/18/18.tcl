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
set debug 0

# retuns {waiting sent}
proc run_instr {regsname curname inboxname outboxname} {
    upvar 1 $regsname regs
    upvar 1 $curname cur
    upvar 1 $inboxname inbox
    upvar 1 $outboxname outbox
    upvar 1 debug debug
    global indata
    set waiting 0
    set sent 0
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

    if {[regexp {rcv ([a-z])} $instr _match reg]} {
        set parsed 1
        if {[llength $inbox] > 0} {
            set regs($reg) [lindex $inbox 0]
            if {$debug} {puts "$reg: $regs($reg)"}
            set inbox [lreplace $inbox 0 0]
        } else {
            set waiting 1
            set cur [expr $cur -1]
        }
    }

    if {[regexp {snd ([-0-9]+)} $instr _match value]} {
        set parsed 1
        lappend outbox $value
        if {$debug} {puts "sending: $value"}
        set sent 1
    }

    if {[regexp {snd ([a-z])} $instr _match reg]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {$debug} {puts "sending from $reg: $regs($reg)"}
        lappend outbox $regs($reg)
        set sent 1
    }

    if {[regexp {add ([a-z]) ([-0-9]+)} $instr _match reg value]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {$debug} {puts -nonewline "$reg: $regs($reg) + $value = "}
        set regs($reg) [expr $regs($reg) + $value]
        if {$debug} {puts "$regs($reg)"}
    }

    if {[regexp {add ([a-z]) ([a-z])} $instr _match reg regvalue]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {![info exists regs($regvalue)]} {
            set regs($regvalue) 0
        }
        if {$debug} {puts -nonewline "$reg: $regs($reg) + $regvalue: $regs($regvalue) = "}
        set regs($reg) [expr $regs($reg) + $regs($regvalue)]
        if {$debug} {puts "$regs($reg)"}
    }
        
    if {[regexp {mul ([a-z]) ([-0-9]+)} $instr _match reg value]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {$debug} {puts -nonewline "$reg: $regs($reg) * $value = "}
        set regs($reg) [expr $regs($reg) * $value]
        if {$debug} {puts "$regs($reg)"}
    }

    if {[regexp {mod ([a-z]) ([-0-9]+)} $instr _match reg value]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {$debug} {puts -nonewline "$reg: $regs($reg) * $value = "}
        set regs($reg) [expr $regs($reg) % $value]
    }

    if {[regexp {mod ([a-z]) ([a-z])} $instr _match reg regvalue]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {![info exists regs($regvalue)]} {
            set regs($regvalue) 0
        }
        set regs($reg) [expr $regs($reg) % $regs($regvalue)]
    }
        
    if {[regexp {jgz ([a-z]) ([-0-9]+)} $instr _match reg value]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {$regs($reg) > 0} {
            set cur [expr $cur + $value - 1]
        }
    }

    # jgz reg
    if {[regexp {jgz ([a-z]) ([a-z])} $instr _match reg regvalue]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {![info exists regs($regvalue)]} {
            set regs($regvalue) 0
        }
        if {$regs($reg) > 0} {
            set cur [expr $cur + $regs($regvalue) - 1]
        }
    }

    if {[regexp {jgz ([-0-9]) ([-0-9]+)} $instr _match reg value]} {
        set parsed 1
        if {$reg > 0} {
            set cur [expr $cur + $value - 1]
        }
    }

    incr cur

    if {$parsed == 0} {
        exit
    }
    return [list $waiting $sent]
}

set waiting 0
set inbox {}
set outbox {}
set cur 0
while {!$waiting} {
    set returns [run_instr regs cur inbox outbox]
    set waiting [lindex $returns 0]
}

puts "Last \"Sound\" played: [lindex $outbox end]"

set p0inbox {}
set p1inbox {}
set p0running 1
set p1running 1
set p0waiting 0
set p1waiting 0
set regs0(p) 0
set regs1(p) 1

set p1sends 0
set cur0 0
set cur1 0

while {$p0running || $p1running} {
    if {$p0running} {
#        puts "p0: [lindex $indata $cur0]"
        set p0return [run_instr regs0 cur0 p0inbox p1inbox]
        set p0waiting [lindex $p0return 0]
        set p0sent    [lindex $p0return 1]
#        puts "p0 wait:   $p0waiting"
#        puts "p0 sent:   $p0sent"
#        puts "p0 inbox:  $p0inbox"
#        puts "p0 outbox: $p1inbox"

        if {$p0waiting == 0} {
            continue
        }
        if {$cur0 < 0 || $cur0 >= [llength $indata]} {
            puts "P0 Stopped"
            set p0running 0
        }
    }

    if {$p1running} {
#        puts "p1: [lindex $indata $cur1]"
        set p1return [run_instr regs1 cur1 p1inbox p0inbox]
        set p1waiting [lindex $p1return 0]
        set p1sent    [lindex $p1return 1]
#        puts "p1 wait:   $p1waiting"
#        puts "p1 sent:   $p1sent"
#        puts "p1 inbox:  $p1inbox"
#        puts "p1 outbox: $p0inbox"

        if {$p1sent} {
            incr p1sends
        }

        if {$cur1 < 0 || $cur1 >= [llength $indata]} {
            puts "P1 Stopped"
            set p1running 0
            break # will not send more
        }
    }
    if {$p1waiting} {
        if {$p0running == 0 || $p0waiting == 1} {
            break
        }
    }
    
}

puts "Number of sends by P1: $p1sends"
