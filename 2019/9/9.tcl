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
    switch $param {
        2 {
            return 2
        }
        1 {
            return 1
        }
        default {
            return 0
        }
    }
}

proc get_value {param mode} {
    upvar 1 program program
    upvar 1 relative_base relative_base
    
    switch $mode {
        0 { # position
            return [get_program $param]
        }
        1 { # immediate
            return $param
        }
        2 { # relative
            return [get_program [expr $param + $relative_base]]
        }
    }
}

proc set_value {param mode value} {
    upvar 1 program program
    upvar 1 relative_base relative_base

    switch $mode {
        0 { # position
            set program($param) $value
        }
        1 { # immediate
            puts "immediate position write"
            exit
        }
        2 { # relative
            set program([expr $param + $relative_base]) $value
        }
    }
}   
    
proc get_program {offset} {
    upvar 1 program program

    if {[info exists program($offset)]} {
        return $program($offset)
    } else {
        return 0
    }
}
    

# This will return on either of these conditions:
#  - Program end (return code 0)
#  - Waiting for additional input (return code 1)
#  - Output value (return code 2)
# Return values is a list with the following content:
#  - First index is return code
#  - Second index is the current ip
#  - Third index is the output value when the return code is 2
#    otherwise zero
#  - Fourth index is the current relative base
proc execute {ip inputs relative_base} {
    upvar 1 program program
    set input_index 0

    while 1 {
        set instruction [get_program $ip]
        set instruction [split $instruction ""]

        set opcode_string [join [lrange $instruction end-1 end] ""]
        scan $opcode_string %d opcode
        set param1_mode [clean_param_mode [lindex $instruction end-2]]
        set param2_mode [clean_param_mode [lindex $instruction end-3]]
        set param3_mode [clean_param_mode [lindex $instruction end-4]]

        switch $opcode {
            1 { # Add
                set param1 [get_program [expr $ip + 1]]
                set param2 [get_program [expr $ip + 2]]
                set param3 [get_program [expr $ip + 3]]
                set calculation [expr [get_value $param1 $param1_mode] + [get_value $param2 $param2_mode]]
                set_value $param3 $param3_mode $calculation
                incr ip 4
            }

            2 { # Mul
                set param1 [get_program [expr $ip + 1]]
                set param2 [get_program [expr $ip + 2]]
                set param3 [get_program [expr $ip + 3]]
                set calculation [expr [get_value $param1 $param1_mode] * [get_value $param2 $param2_mode]]
                set_value $param3 $param3_mode $calculation
                incr ip 4
            }

            3 { # Input
                set param1 [get_program [expr $ip + 1]]
                if {$input_index < [llength $inputs]} {
                    set value [lindex $inputs $input_index]
                    incr input_index
                } else {
                    return [list 1 $ip 0 $relative_base]
                }
                set_value $param1 $param1_mode $value
                incr ip 2
            }

            4 { # Output
                set param1 [get_program [expr $ip + 1]]
                set value [get_value $param1 $param1_mode]
                incr ip 2

                return [list 2 $ip $value $relative_base]
            }

            5 { # jump if true
                set param1 [get_program [expr $ip + 1]]
                set param2 [get_program [expr $ip + 2]]
                if {[get_value $param1 $param1_mode]} {
                    set ip [get_value $param2 $param2_mode]
                } else {
                    incr ip 3
                }
            }

            6 { # jump if fale
                set param1 [get_program [expr $ip + 1]]
                set param2 [get_program [expr $ip + 2]]
                if {![get_value $param1 $param1_mode]} {
                    set ip [get_value $param2 $param2_mode]
                } else {
                    incr ip 3
                }
            }

            7 { # less than
                set param1 [get_program [expr $ip + 1]]
                set param2 [get_program [expr $ip + 2]]
                set param3 [get_program [expr $ip + 3]]
                if {[get_value $param1 $param1_mode] < [get_value $param2 $param2_mode]} {
                    set calculation 1
                } else {
                    set calculation 0
                }
                set_value $param3 $param3_mode $calculation
                incr ip 4
            }

            8 { # equals
                set param1 [get_program [expr $ip + 1]]
                set param2 [get_program [expr $ip + 2]]
                set param3 [get_program [expr $ip + 3]]
                if {[get_value $param1 $param1_mode] == [get_value $param2 $param2_mode]} {
                    set calculation 1
                } else {
                    set calculation 0
                } 
                set_value $param3 $param3_mode $calculation
                incr ip 4
            }
            9 {
                set param1 [get_program [expr $ip + 1]]
                set relative_base [expr $relative_base + [get_value $param1 $param1_mode]]
                incr ip 2
            }

            99 {
                return [list 0 $ip 0 0]
            }

            default {
                puts "Something is wrong"
                exit
            }
        }
    }
}

# Convert the program to an array
set pos 0
foreach data $indata {
    set program($pos) $data
    incr pos
}

set ip            0
set inputs        [list 1]
set relative_base 0
set return_code   1
while {$return_code != 0} {
    lassign [execute $ip $inputs $relative_base] return_code ip output relative_base

    if {$return_code == 2} {
        puts "BOOST keycode: $output"
    }
}

# Reconvert the program since it has been modified by the last run
array unset program
set pos 0
foreach data $indata {
    set program($pos) $data
    incr pos
}

set ip            0
set inputs        [list 2]
set relative_base 0
set return_code 1
while {$return_code != 0} {
    lassign [execute $ip $inputs $relative_base] return_code ip output relative_base

    if {$return_code == 2} {
        puts "Coordinates: $output"
    }
}
