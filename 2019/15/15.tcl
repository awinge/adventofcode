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

proc get_boundaries {} {
    upvar 1 grid grid

    foreach {coords color} [array get grid] {
        lassign [split $coords ","] x y

        if {![info exists min_x] || $x < $min_x} {
            set min_x $x
        }

        if {![info exists max_x] || $x > $max_x} {
            set max_x $x
        }

        if {![info exists min_y] || $y < $min_y} {
            set min_y $y
        }

        if {![info exists max_y] || $y > $max_y} {
            set max_y $y
        }
    }
    return [list $min_x $min_y $max_x $max_y]
}

proc print {boundaries} {
    upvar 1 grid grid
    upvar 1 x droid_x
    upvar 1 y droid_y
    
    lassign $boundaries min_x min_y max_x max_y
    
    for {set y $min_y} {$y <= $max_y} {incr y} {
        for {set x $min_x} {$x <= $max_x} {incr x} {
            if {$x == $droid_x && $y == $droid_y} {
                puts -nonewline "D"
            } else {
                if {[info exists grid($x,$y)]} {
                    puts -nonewline "$grid($x,$y)"
                } else {
                    puts -nonewline " "
                }
            }
        }
        puts ""
    }
}

proc move {x y direction} {
    switch $direction {
        1 -
        "north" {
            incr y -1
        }
        2 -
        "south" {
            incr y 1
        }
        3 -
        "west" {
            incr x -1
        }
        4 -
        "east" {
            incr x 1
        }
        default {
            puts "Invalid direction: $direction"
            exit
        }
    }
    return [list $x $y]
}

proc move_back {direction} {
    switch $direction {
        "north" {
            return "south"
        }
        "south" {
            return "north"
        }
        "west" {
            return "east"
        }
        "east" {
            return "west"
        }
        default {
            puts "Invalid direciton: $direction"
            exit
        }
    }
}

proc run_explore {} {
    upvar 1 program program
    upvar 1 grid grid
    upvar 1 x x
    upvar 1 y y
    upvar 1 dirs dirs
    upvar 1 ip ip
    upvar 1 relative_base relative_base
    upvar 1 return_code return_code
    
    set input []
    
    while {$return_code != 0} {
        lassign [execute $ip $input $relative_base] return_code ip output relative_base

        switch $return_code {
            1 { #input
                set dir "north"
                lassign [move $x $y $dir] new_x new_y
                if {![info exists grid($new_x,$new_y)]} {
                    set input [list $dirs($dir)]
                    continue
                }
                
                set dir "east"
                lassign [move $x $y $dir] new_x new_y
                if {![info exists grid($new_x,$new_y)]} {
                    set input [list $dirs($dir)]
                    continue
                }

                set dir "south"
                lassign [move $x $y $dir] new_x new_y
                if {![info exists grid($new_x,$new_y)]} {
                    set input [list $dirs($dir)]
                    continue
                }

                set dir "west"
                lassign [move $x $y $dir] new_x new_y
                if {![info exists grid($new_x,$new_y)]} {
                    set input [list $dirs($dir)]
                    continue
                }

                # Backtrack the path already taken
                if {$path != []} {
                    set dir [move_back [lindex $path end]]
                    lassign [move $x $y $dir] new_x new_y
                    set path [lreplace $path end end]
                    set input [list $dirs($dir)]
                    continue
                }
                break
            }
            2 { #output
                set input []
                switch $output {
                    0 { # Wall
                        set grid($new_x,$new_y) "#"
                    }
                    1 { # Moved
                        set x $new_x
                        set y $new_y
                        if {![info exists grid($x,$y)]} {
                            lappend path $dir
                            set grid($x,$y) " "
                        }
                    }
                    2 { # Moved and found system
                        set x $new_x
                        set y $new_y
                        if {![info exists grid($x,$y)]} {
                            lappend path $dir
                            set grid($x,$y) "o"
                            puts "Minimal steps to find oxygen system: [llength $path]"
                            break
                        }
                        
                    }
                }
#                exec tput cup 0 0 >/dev/tty
#                print [get_boundaries]
#                after 10
            }
        }
    }
}

proc run_oxygen {} {
    upvar 1 program program
    upvar 1 grid grid
    upvar 1 x x
    upvar 1 y y
    upvar 1 dirs dirs
    upvar 1 ip ip
    upvar 1 relative_base relative_base
    upvar 1 return_code return_code

    set input []
    while {$return_code != 0} {
        lassign [execute $ip $input $relative_base] return_code ip output relative_base

        switch $return_code {
            1 { #input
                set dir "north"
                lassign [move $x $y $dir] new_x new_y
                if {![info exists grid($new_x,$new_y)] || $grid($new_x,$new_y) == " "} {
                    set input [list $dirs($dir)]
                    continue
                }
                
                set dir "east"
                lassign [move $x $y $dir] new_x new_y
                if {![info exists grid($new_x,$new_y)] || $grid($new_x,$new_y) == " "} {
                    set input [list $dirs($dir)]
                    continue
                }

                set dir "south"
                lassign [move $x $y $dir] new_x new_y
                if {![info exists grid($new_x,$new_y)] || $grid($new_x,$new_y) == " "} {
                    set input [list $dirs($dir)]
                    continue
                }

                set dir "west"
                lassign [move $x $y $dir] new_x new_y
                if {![info exists grid($new_x,$new_y)] || $grid($new_x,$new_y) == " "} {
                    set input [list $dirs($dir)]
                    continue
                }

                # Backtrack the path already taken
                if {$path != []} {
                    set dir [move_back [lindex $path end]]
                    lassign [move $x $y $dir] new_x new_y
                    set path [lreplace $path end end]
                    set input [list $dirs($dir)]
                    continue
                }
                    
                puts "Minutes to fill with oxygen: $max_path_length"
                break
            }
            2 { #output
                set input []
                switch $output {
                    0 { # Wall
                        set grid($new_x,$new_y) "#"
                    }
                    1 -
                    2 { # Moved
                        set x $new_x
                        set y $new_y
                        if {![info exists grid($x,$y)] || $grid($x,$y) == " "} {
                            lappend path $dir
                            set grid($x,$y) "O"

                            if {![info exists max_path_length] || [llength $path] > $max_path_length} {
                                set max_path_length [llength $path]
                            }
                        }
                    }
                }
#                exec tput cup 0 0 >/dev/tty
#                print [get_boundaries]
#                after 10
            }
        }
    }
}

# Direction lookup
set dirs(1) "north"
set dirs(2) "south"
set dirs(3) "west"
set dirs(4) "east"
foreach {k v} [array get dirs] {
    set dirs($v) $k
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

# Set start position
set x 0
set y 0
set grid($x,$y) " "

#exec clear >@ stdout
run_explore

# Start from the oxygen system
set grid($x,$y) "O"
#exec clear >@ stdout
run_oxygen
