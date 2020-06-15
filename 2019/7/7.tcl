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

# This will return on either of these conditions:
#  - Program end (return code 0)
#  - Waiting for additional input (return code 1)
#  - Output value (return code 2)
# Return values is a list with the following content:
#  - First index is return code
#  - Second index is the current program
#  - Third index is the current ip
#  - Fourth index is the output value when the return code is 2
#    otherwise zero
proc execute {program ip inputs} {
    set input_index 0

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
                if {$input_index < [llength $inputs]} {
                    set value [lindex $inputs $input_index]
                    incr input_index
                } else {
                    return [list 1 $program $ip 0]
                }

                set program [lreplace $program $param1 $param1 $value]
                incr ip 2
            }

            4 { # Output
                set param1 [lindex $program [expr $ip + 1]]
                set value [get_value $param1 $param1_mode]
                incr ip 2

                return [list 2 $program $ip $value]
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
                return [list 0 $program $ip 0]
            }

            default {
                puts "Something is wrong"
                exit
            }
        }
    }
}

proc execute_chain {program phases} {
    set inputs   [lrepeat [llength $phases] {}       ]
    set programs [lrepeat [llength $phases] $program ]
    set ips      [lrepeat [llength $phases] 0        ]
    set running  [lrepeat [llength $phases] 1        ]

    # Setting inital inputs (phases)
    for {set i 0} {$i < [llength $phases]} {incr i} {
        set input [lindex $phases $i]
        set inputs [lreplace $inputs $i $i $input]
    }


    # Set initial input value
    set input [lindex $inputs 0]
    lappend input 0
    set inputs [lreplace $inputs 0 0 $input]

    while {$running != [lrepeat [llength $phases] 0]} {
        for {set i 0} {$i < [llength $phases]} {incr i} {
            if {[lindex $running $i] == 1 && [lindex $inputs $i] != {}} {
                set running_program [lindex $programs $i]
                set running_ip      [lindex $ips $i]
                
                set stopped 0
                while {$stopped == 0} {
                    lassign [execute $running_program $running_ip [lindex $inputs $i]] return_code running_program running_ip output
                    set inputs [lreplace $inputs $i $i {}]
                    
                    if {$return_code == 0} { # program end
                        set running [lreplace $running $i $i 0]
                        set stopped 1
                    }
                    
                    if {$return_code == 1} { # waiting for input
                        set stopped 1
                    }
                    
                    if {$return_code == 2} { # Output value
                        if {$i == [expr [llength $phases] - 1]} {
                            set last_output $output
                        }
                        set input_index [expr ($i + 1) % [llength $phases]]
                        set input [lindex $inputs $input_index]
                        lappend input $output
                        set inputs [lreplace $inputs $input_index $input_index $input]
                    }
                }
                
                # Save the state
                set programs [lreplace $programs $i $i $running_program]
                set ips      [lreplace $ips      $i $i $running_ip]
            }
        }
    }
    return $last_output
}

proc get_max {program input_phases selected_phases} {
    global max_value
    
    if {$input_phases == {}} {
        set value [execute_chain $program $selected_phases]
        
        if {![info exists max_value] || $value > $max_value} {
            set max_value $value
            return
        }
    }

    for {set index 0} {$index < [llength $input_phases]} {incr index} {
        set tmp $selected_phases
        lappend tmp [lindex $input_phases $index]
        get_max $program [lreplace $input_phases $index $index] $tmp
    }
}

set phases [list 0 1 2 3 4]
get_max $indata $phases {}
puts "Maximum thrust: $max_value"

set phases [list 9 8 7 6 5]
get_max $indata $phases {}
puts "Maximum thrust: $max_value"
