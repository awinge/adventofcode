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
#  - Running (return code 3)

# Return values is a list with the following content:
#  - First index is return code
#  - Second index is the current ip
#  - Third index is the output value when the return code is 2
#    otherwise zero
#  - Fourth index is the current relative base
#  - Fifth index is the unused inputs
proc execute {ip inputs relative_base} {
    upvar 1 program program

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

    return [list 3 $ip 0 $relative_base $inputs]
}

proc print {} {
    exec tput cup 0 0 >/dev/tty
    for {set p 0} {$p < 50} {incr p} {
        upvar 2 ip${p} ip
        upvar 2 queue${p} queue
        puts "$p: $ip    $queue                                                                                           "
    }
}

proc all_idle {} {
    for {set p 0} {$p < 50} {incr p} {
        upvar 2 idle_count${p} idle_count
        if {$idle_count <= 1} {
            return 0
        }
    }
    return 1
}

proc run_nodes {} {
    set netaddr 0
    while 1 {
        upvar 1 program${netaddr} program
        upvar 1 ip${netaddr} ip
        upvar 1 relative_base${netaddr} relative_base
        upvar 1 return_code${netaddr} return_code
        upvar 1 queue${netaddr} queue
        upvar 1 packet${netaddr} packet
        upvar 1 idle_count${netaddr} idle_count
        
        lassign [execute $ip $queue $relative_base] return_code ip output relative_base queue

        switch $return_code {
            1 { #input
                if {$queue == []} {
                    set queue [list -1]
                    incr idle_count
                }
            }
            2 {
                lappend packet $output

                # Send the packet
                if {[llength $packet] == 3} {
                    set dest_node [lindex $packet 0]

                    if {$dest_node == 255} {
                        if {![info exists nat_y]} {
                            puts "The first Y value sent to NAT: [lindex $packet 2]"
                        }
                        set nat_x [lindex $packet 1]
                        set nat_y [lindex $packet 2]
                    }

                    upvar 1 queue${dest_node} dest_queue
                    upvar 1 idle_count${dest_node} dest_count
                    lappend dest_queue [lindex $packet 1]
                    lappend dest_queue [lindex $packet 2]
                    set dest_count 0
                    set packet []
                }
            }
        }

        if {[all_idle]} {
            if {[info exists last_nat_sent] && $last_nat_sent == $nat_y} {
                puts "$nat_y sent twice in a row by NAT"
                exit
            } else {
                upvar 1 queue0      dest_queue
                upvar 1 idle_count0 dest_count
                lappend dest_queue $nat_x
                lappend dest_queue $nat_y
                set dest_count 0
            }
            set last_nat_sent $nat_y
        }
        
        
        while 1 {
            incr netaddr
            if {$netaddr >= 50} {
                set netaddr 0
            }
            upvar 1 idle_count${netaddr} idle_count
            if {$idle_count <= 1} {
                break
            }
        }
    }
}


# Convert the program to an array
set pos 0
foreach data $indata {
    for {set p 0} {$p < 50} {incr p} {
        set program${p}($pos) $data
    }
    incr pos
}

# Set start parameters
for {set p 0} {$p < 50} {incr p} {
    set ip${p} 0
    set relative_base${p} 0
    set return_code${p} 3
    set queue${p} [list $p]
    set idle_count${p} 0
}

run_nodes
