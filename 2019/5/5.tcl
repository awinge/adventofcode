#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd ","] {
    if {$row != ""} {
	lappend indata [regexp -inline -all -- {\S+} $row]
    }
}

proc clean_param_mode {param} {
    if {$param == 1} {
        return 1
    } else {
        return 0
    }
}

proc get_value {param mode} {
    upvar 1 program program
    switch $mode {
        0 { # position 
            return [lindex $program $param]
        }
        1 { # immediate
            return $param
        }
    }
}

proc execute {program} {
    set ip 0

    while 1 {
        set instruction [lindex $program $ip]
        set instruction [split $instruction ""]

        set opcode_string [join [lrange $instruction end-1 end] ""]
        scan $opcode_string %d opcode
        set param1_mode [clean_param_mode [lindex $instruction end-2]]
        set param2_mode [clean_param_mode [lindex $instruction end-3]]
        set param3_mode [clean_param_mode [lindex $instruction end-4]]

        switch $opcode {
            1 { # Add
                set param1 [lindex $program [expr $ip + 1]]
                set param2 [lindex $program [expr $ip + 2]]
                set param3 [lindex $program [expr $ip + 3]]
                set calculation [expr [get_value $param1 $param1_mode] + [get_value $param2 $param2_mode]]
                set program [lreplace $program $param3 $param3 $calculation]
                incr ip 4
            }
            2 { # Mul
                set param1 [lindex $program [expr $ip + 1]]
                set param2 [lindex $program [expr $ip + 2]]
                set param3 [lindex $program [expr $ip + 3]]
                set calculation [expr [get_value $param1 $param1_mode] * [get_value $param2 $param2_mode]]
                set program [lreplace $program $param3 $param3 $calculation]
                incr ip 4
            }
            3 { # Input
                set param1 [lindex $program [expr $ip + 1]]
                puts "Enter a value: "
                gets stdin value
                scan $value %d value
                set program [lreplace $program $param1 $param1 $value]
                incr ip 2
            }
            4 { # Output
                set param1 [lindex $program [expr $ip + 1]]
                puts "Value output: [get_value $param1 $param1_mode]"
                incr ip 2
            }
            5 { # jump if true
                set param1 [lindex $program [expr $ip + 1]]
                set param2 [lindex $program [expr $ip + 2]]
                if {[get_value $param1 $param1_mode]} {
                    set ip [get_value $param2 $param2_mode]
                } else {
                    incr ip 3
                }
            }                
            6 { # jump if fale
                set param1 [lindex $program [expr $ip + 1]]
                set param2 [lindex $program [expr $ip + 2]]
                if {![get_value $param1 $param1_mode]} {
                    set ip [get_value $param2 $param2_mode]
                } else {
                    incr ip 3
                }
            }

            7 { # less than
                set param1 [lindex $program [expr $ip + 1]]
                set param2 [lindex $program [expr $ip + 2]]
                set param3 [lindex $program [expr $ip + 3]]
                if {[get_value $param1 $param1_mode] < [get_value $param2 $param2_mode]} {
                    set calculation 1
                } else {
                    set calculation 0
                }
                set program [lreplace $program $param3 $param3 $calculation]
                incr ip 4
            }

            8 { # equals
                set param1 [lindex $program [expr $ip + 1]]
                set param2 [lindex $program [expr $ip + 2]]
                set param3 [lindex $program [expr $ip + 3]]
                if {[get_value $param1 $param1_mode] == [get_value $param2 $param2_mode]} {
                    set calculation 1
                } else {
                    set calculation 0
                }
                set program [lreplace $program $param3 $param3 $calculation]
                incr ip 4
            }
                
            99 {
                return $program 
            }
            default {
                puts "Something is wrong"
                exit
            }
        }
    }
}

execute $indata
