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

proc run_print {} {
    upvar 1 program program
    upvar 1 ip ip
    upvar 1 relative_base relative_base
    upvar 1 return_code return_code
    upvar 1 grid grid
    
    set input []
    set x 0
    set y 0
    
    while {$return_code != 0} {
        lassign [execute $ip $input $relative_base] return_code ip output relative_base

        switch $return_code {
            1 { #input
                exit
            }
            2 {
                switch $output {
                    10 {
                        set x 0
                        incr y
                    }
                    default {
                        set grid($x,$y) [format %c $output]
                        incr x
                    }
                }
                puts -nonewline [format %c $output]
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

# Set start parameters
set ip 0
set relative_base 0
set return_code 3

run_print

set sum 0
foreach {k v} [array get grid] {
    lassign [split $k ","] x y

    if {$v != "#"} {
        continue
    }
    
    set left  "[expr $x - 1],$y"
    set right "[expr $x + 1],$y"
    set up    "$x,[expr $y - 1]"
    set down  "$x,[expr $y + 1]"
    
    if {![info exists grid($left)] || $grid($left) != "#"} {
        continue
    }
    if {![info exists grid($right)] || $grid($right) != "#"} {
        continue
    }
    if {![info exists grid($up)] || $grid($up) != "#"} {
        continue
    }
    if {![info exists grid($down)] || $grid($down) != "#"} {
        continue
    }
    
    set sum [expr $sum + $x * $y]
}

puts "The sum of alignment parameters: $sum"


# Convert the program to an array again
set pos 0
foreach data $indata {
    set program($pos) $data
    incr pos
}

# Wake up vacuum robot
set program(0) 2

# Set start parameters
set ip 0
set relative_base 0
set return_code 3

set main       "C,B,C,A,A,C,B,A,B,B"
set program_a  "L,8,R,6,R,6,R,10,L,8"
set program_b  "L,12,R,8,R,8"
set program_c  "L,8,R,10,L,8,R,8"
set cont_print "n"

foreach char [split $main ""] {
    lappend programming [scan $char %c]
}
lappend programming 10
foreach char [split $program_a ""] {
    lappend programming [scan $char %c]
}
lappend programming 10
foreach char [split $program_b ""] {
    lappend programming [scan $char %c]
}
lappend programming 10
foreach char [split $program_c ""] {
    lappend programming [scan $char %c]
}
lappend programming 10
foreach char [split $cont_print ""] {
    lappend programming [scan $char %c]
}
lappend programming 10

proc run_cleaning {} {
    upvar 1 program program
    upvar 1 ip ip
    upvar 1 relative_base relative_base
    upvar 1 return_code return_code
    upvar 1 grid grid
    upvar 1 programming programming

    set input []
    set programming_index 0

    while {$return_code != 0} {
        lassign [execute $ip $input $relative_base] return_code ip output relative_base

        set input []
        
        switch $return_code {
            1 { #input
                set input [lindex $programming $programming_index]
                incr programming_index
            }
            2 {
                if {$output <= 255} {
                    #puts -nonewline [format %c $output]
                } else {
                    puts "Dust collected: $output"
                }
            }
        }
    }
}

run_cleaning
