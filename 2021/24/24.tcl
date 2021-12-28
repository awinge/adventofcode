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


# Proc for running the program from start to finish with inputs as a list
# Returns the new state of x y z w as a list
# Only used for debug to see if the do proc below procudes the same result
proc run {x y z w program start finish input} {
    if {$finish == "end"} {
        set finish [expr [llength $program] - 1]
    }

    for {set i $start} {$i <= $finish} {incr i} {
        set instr [lindex $program $i]

        if {[regexp {inp ([a-z])} $instr match var]} {
            set $var [lindex $input 0]
            set input [lreplace $input 0 0]
            continue
        }

        if {[regexp {(add|mul|div|mod|eql) ([a-z]+) ([0-9-]+)} $instr match op var value]} {
            switch $op {
                add { set $var [expr [set $var] + $value] }
                mul { set $var [expr [set $var] * $value] }
                div { set $var [expr [set $var] / $value] }
                mod { set $var [expr [set $var] % $value] }
                eql { if {[set $var] == $value} { set $var 1 } else { set $var 0 } }
                default {
                    puts "Unknown op: $op"
                    exit
                }
            }
            continue
        }

        if {[regexp {(add|mul|div|mod|eql) ([a-z]+) ([a-z]+)} $instr match op var1 var2]} {
            switch $op {
                add { set $var1 [expr [set $var1] + [set $var2]] }
                mul { set $var1 [expr [set $var1] * [set $var2]] }
                div { set $var1 [expr [set $var1] / [set $var2]] }
                mod { set $var1 [expr [set $var1] % [set $var2]] }
                eql { if {[set $var1] == [set $var2]} { set $var1 1 } else { set $var1 0 } }
                default {
                    puts "Unknown op: $op"
                    exit
                }
            }
            continue
        }

        puts "Unparsed: $instr"
        exit
    }
    return [list $x $y $z $w]
}


# Proc for running a step with state z and input w
# Returns the new state z
#
# This proc contains the parameters extracted from my input
proc do {step z w} {
    set param1 {12 13 13 -2 -10 13 -14 -5 15 15 -14 10 -14 -5}
    set param2 { 1  1  1 26  26  1  26 26  1  1  26  1  26 26}
    set param3 { 7  8 10  4   4  6  11 13  1  8   4 13   4 14}

    set param1 [lindex $param1 $step]
    set param2 [lindex $param2 $step]
    set param3 [lindex $param3 $step]

    set x [expr ($z % 26) + $param1]
    set z [expr $z / $param2]

    if {$x != $w} {
        set x 1
    } else {
        set x 0
    }

    set z [expr $z * ((25 * $x) + 1)]
    set z [expr $z + (($w + $param3) * $x)]

    return $z
}


# Proc for bruteforce
# Use memoization for when all numbers have been tested for
# a specific step with inital value of z.
proc bf {z step values part} {
    global memo
    global finished

    if {$finished} {
        return
    }

    if {[info exist memo($z,$step)]} {
        return
    }

    if {$step >= 14} {
        if {$z == 0} {
            puts "Model number: [join $values ""]"
            set finished 1
        }
        return

    }

    if {$part == 1} {
        for {set i 9} {$i >= 1} {incr i -1} {
            set new_values [list {*}$values $i]
            set nz [do $step $z $i]
            bf $nz [expr $step + 1] $new_values $part
        }
    } else {
        for {set i 1} {$i <= 9} {incr i} {
            set new_values [list {*}$values $i]
            set nz [do $step $z $i]
            bf $nz [expr $step + 1] $new_values $part
        }
    }

    set memo($z,$step) 1
}


# Bruteforce part 1
set finished 0
bf 0 0 {} 1

array unset memo

# Bruteforce part 2
set finished 0
bf 0 0 {} 2
