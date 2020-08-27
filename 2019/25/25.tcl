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
#  - Fifth index is the unused inputs
proc execute {ip inputs relative_base} {
    upvar 1 program program

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
                if {$inputs != []} {
                    set value [lindex $inputs 0]
                    set inputs [lreplace $inputs 0 0]
                } else {
                    return [list 1 $ip 0 $relative_base $inputs]
                }
                set_value $param1 $param1_mode $value
                incr ip 2
            }

            4 { # Output
                set param1 [get_program [expr $ip + 1]]
                set value [get_value $param1 $param1_mode]
                incr ip 2

                return [list 2 $ip $value $relative_base $inputs]
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
                return [list 0 $ip 0 0 $inputs]
            }

            default {
                puts "Something is wrong"
                exit
            }
        }
    }
}

proc run {} {
    upvar 1 program program
    upvar 1 ip ip
    upvar 1 relative_base relative_base
    upvar 1 return_code return_code
    upvar 1 grid grid
    upvar 1 input input
    
    while {$return_code != 0} {
        lassign [execute $ip $input $relative_base] return_code ip output relative_base input

        switch $return_code {
            1 { #input
                set text [gets stdin]
                foreach char [split $text ""] {
                    lappend input [scan $char %c]
                }
                lappend input 10
            }
            2 {
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

set sequence { \
    "north" "take mouse"                         # Hallway mouse
    "north" "take pointer"                       # Kitchen
    "east"                                       # Gift Wrapping Center, electromagnet
    "south"                                      # Passages
    "north" "west" "south" "south"               # Going back Hull Breach
    "north" "east"                               # Holodeck, escape pod
    "west" "south"                               # Going back Hull Breach
    "west" "take monolith"                       # Stables
    "north"                                      # Sick Bay, molten lava
    "west" "take food ration"                    # Observatory
    "south" "take space law space brochure"      # Hot chocolate Fountain
    "north" "east" "south"                       # Going back Stables
    "south" "take sand"                          # Navigation
    "south"                                      # Corridor
    "west" "take asterisk"                       # Warp Drive Maintenance
    "south" "take mutex"                         # Storage
    "west"                                       # Crew quarters
    "east" "north" "east" "north" "north" "east" # Going back to Hull Breach
    "south"                                      # Arcade, infinite loop
    "south"                                      # Science Lab
    "west"                                       # Engineering, photons
    "south"                                      # Security Checkpoint
}

set sequence { \
    "west"
    "north"
    "west" "take food ration"
    "south" "take space law space brochure"
    "north" "east" "south"
    "south"
    "south"
    "west" "take asterisk"
    "south" "take mutex"
    "north" "east" "north" "north" "east"
    "south"
    "south"
    "west"
    "south"
    "east"
}

foreach word $sequence {
    foreach char [split $word ""] {
        lappend input [scan $char %c]
    }
    lappend input 10
}

run
