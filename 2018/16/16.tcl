#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	lappend indata $row
    }
}

# Parse the inputs into two lists.
# Test lits, contains three lists:
#   before, instruction, after
# Program list which contains all instructions
set test [list]
foreach data $indata {
    if {[regexp {Before: *\[([\d]*), ([\d]*), ([\d]*), ([\d]*)\]} $data _match rega regb regc regd]} {
        lappend test [list $rega $regb $regc $regd]
    }

    if {[regexp {([\d]*) ([\d]*) ([\d]*) ([\d]*)} $data _match op a b c]} {
        if {$test != [list]} {
            lappend test [list $op $a $b $c]
        } else {
            lappend program [list $op $a $b $c]
        }
    }


    if {[regexp {After: *\[([\d]*), ([\d]*), ([\d]*), ([\d]*)\]} $data _match rega regb regc regd]} {
        lappend test [list $rega $regb $regc $regd]
        lappend tests $test
        set test [list]
    }
}

# One proc per possible instruction
proc addr {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] + [lindex $regs $b]]
    return $regs
}

proc addi {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] + $b]
    return $regs
}

proc mulr {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] * [lindex $regs $b]]
    return $regs
}

proc muli {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] * $b]
    return $regs
}

proc banr {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] & [lindex $regs $b]]
    return $regs
}

proc bani {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] & $b]
    return $regs
}

proc borr {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] | [lindex $regs $b]]
    return $regs
}

proc bori {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] | $b]
    return $regs
}

proc setr {regs instr} {
    lassign $instr op a b c

    lset regs $c [lindex $regs $a]
    return $regs
}

proc seti {regs instr} {
    lassign $instr op a b c

    lset regs $c $a
    return $regs
}

proc gtir {regs instr} {
    lassign $instr op a b c

    if {$a > [lindex $regs $b]} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

proc gtri {regs instr} {
    lassign $instr op a b c

    if {[lindex $regs $a] > $b} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

proc gtrr {regs instr} {
    lassign $instr op a b c

    if {[lindex $regs $a] > [lindex $regs $b]} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

proc eqir {regs instr} {
    lassign $instr op a b c

    if {$a == [lindex $regs $b]} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

proc eqri {regs instr} {
    lassign $instr op a b c

    if {[lindex $regs $a] == $b} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

proc eqrr {regs instr} {
    lassign $instr op a b c

    if {[lindex $regs $a] == [lindex $regs $b]} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

# Set a list of all possible instructions
set instructions [list addr addi mulr muli banr bani borr bori setr seti gtir gtri gtrr eqir eqri eqrr]

# Check all instructions for all tests and see which ones
# match three or more instrunctions
set three 0
foreach test $tests {
    lassign $test regs instr result

    set match 0
    foreach instruction $instructions {
        set testregs [$instruction $regs $instr]
        if {$result == $testregs} {
            incr match
        }
    }

    if {$match >= 3} {
        incr three
    }
}
puts "Three or more possible matches: $three"

# Set all instrunctions possible for all opcodes
# Remove instrunctions that does not match during a test
set possibles [lrepeat 16 $instructions]
foreach test $tests {
    lassign $test regs instr result
    lassign $instr opcode

    set new_possible [list]
    foreach instruction [lindex $possibles $opcode]  {
        set testregs [$instruction $regs $instr]
        if {$result == $testregs} {
            lappend new_possible $instruction
        }
    }
    lset possibles $opcode $new_possible
}

# Proc to check if there is a unique instruction for all opcodes
proc all_unique {possibles} {
    foreach possible $possibles {
        if {[llength $possible] > 1} {
            return 0
        }
    }
    return 1
}

# Remove an instruction from all possibilities when it has become unique
# Do this until all are unique
while {[all_unique $possibles] != 1} {
    foreach possible $possibles {
        if {[llength $possible] == 1} {
            lassign $possible unique

            # Found a quique instruction, remove that from all other
            for {set i 0} {$i < [llength $possibles]} {incr i} {
                set p [lindex $possibles $i]

                if {[llength $p] > 1} {
                    set new [list]
                    for {set j 0} {$j < [llength $p]} {incr j} {
                        set inst [lindex $p $j]
                        if {$inst != $unique} {
                            lappend new $inst
                        }
                    }
                    lset possibles $i $new
                }
            }
        }
    }
}

# Initialize regs and run the program
set regs [list 0 0 0 0]
foreach instr $program {
    lassign $instr opcode
    set p [lindex $possibles $opcode]
    set regs [$p $regs $instr]
}

puts "Register 0 after execution: [lindex $regs 0]"
