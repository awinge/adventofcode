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

# Read in the map
set x 0
set y 0
foreach line $indata {
    foreach char [split $line ""] {
        set map($x,$y) $char
        incr x
        if {[regexp {[a-z]} $char]} {
            incr wanted_keys
        }
    }
    set x 0
    incr y
}

# Get boundaries of map
proc get_boundaries {} {
    upvar 1 map map

    foreach {key value} [array get map] {
        lassign [split $key ","] x y

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

# Print the map
proc print {boundaries} {
    upvar 1 map map

    lassign $boundaries min_x min_y max_x max_y

    for {set y $min_y} {$y <= $max_y} {incr y} {
        for {set x $min_x} {$x <= $max_x} {incr x} {
            if {[info exists map($x,$y)]} {
                puts -nonewline "$map($x,$y)"
            } else {
                puts -nonewline " "
            }
        }
        puts ""
    }
}

# Find coord for a specific character
# If multiple exists the first found coord is returned
proc find_coord {char} {
    upvar 1 map map

    foreach {key value} [array get map] {
        if {$value == $char} {
            return $key
        }
    }
    puts "Could not find $char in map"
    exit
}

# Do a move
proc move {x y z direction} {
    upvar 1 tele tele

    switch $direction {
        "north" {
            incr y -1
        }
        "south" {
            incr y 1
        }
        "west" {
            incr x -1
        }
        "east" {
            incr x 1
        }
        "tele" {
            if {![info exist tele($x,$y)]} {
                puts "No teleporter"
            } else {
                lassign [split $tele($x,$y) ","] x y z_diff
                incr z $z_diff
            }
        }

        default {
            puts "Invalid direction: $direction"
            exit
        }
    }
    return [list $x $y $z]
}

# Get possible movements from a location
proc get_movements {x y z steps} {
    upvar 1 map map
    upvar 1 tele tele

    # Check ordinary movements
    foreach dir {"north" "west" "south" "east" "tele"} {
        if {$dir != "tele" || $map($x,$y) == "¤"} {
            lassign [move $x $y $z $dir] new_x new_y new_z
            if {[info exists map($new_x,$new_y)] && $new_z >= 0} {
                if {[regexp {[!@.¤]} $map($new_x,$new_y)]} {
                    lappend movements [list $new_x $new_y $new_z [expr $steps + 1]]
                }
            }
        }
    }
    return $movements
}

proc parse_map {} {
    upvar 1 map map
    upvar 1 tele tele

    foreach {k v} [array get map] {
        # Only check for open passages
        if {$v != "."} {
            continue
        }

        # Get the coordinat
        lassign [split $k ","] x y

        set name ""
        # Check above
        lassign [move $x $y 1 "north"] n_x n_y
        if {[info exists map($n_x,$n_y)] && [regexp {[A-Z]} $map($n_x,$n_y)]} {
            lassign [move $n_x $n_y 1 "north"] nn_x nn_y
            set name "$map($nn_x,$nn_y)$map($n_x,$n_y)"

            lassign [move $nn_x $nn_y 1 "north"] nnn_x nnn_y
            if {[info exists map($nnn_x,$nnn_y)]} {
                set level +1
            } else {
                set level -1
            }
        }

        # Check below
        lassign [move $x $y 1 "south"] n_x n_y
        if {[info exists map($n_x,$n_y)] && [regexp {[A-Z]} $map($n_x,$n_y)]} {
            lassign [move $n_x $n_y 1 "south"] nn_x nn_y
            set name "$map($n_x,$n_y)$map($nn_x,$nn_y)"

            lassign [move $nn_x $nn_y 1 "south"] nnn_x nnn_y
            if {[info exists map($nnn_x,$nnn_y)]} {
                set level +1
            } else {
                set level -1
            }
        }

        # Check left
        lassign [move $x $y 1 "west"] n_x n_y
        if {[info exists map($n_x,$n_y)] && [regexp {[A-Z]} $map($n_x,$n_y)]} {
            lassign [move $n_x $n_y 1 "west"] nn_x nn_y
            set name "$map($nn_x,$nn_y)$map($n_x,$n_y)"

            lassign [move $nn_x $nn_y 1 "west"] nnn_x nnn_y
            if {[info exists map($nnn_x,$nnn_y)]} {
                set level +1
            } else {
                set level -1
            }
        }

        # Check right
        lassign [move $x $y 1 "east"] n_x n_y
        if {[info exists map($n_x,$n_y)] && [regexp {[A-Z]} $map($n_x,$n_y)]} {
            lassign [move $n_x $n_y 1 "east"] nn_x nn_y
            set name "$map($n_x,$n_y)$map($nn_x,$nn_y)"

            lassign [move $nn_x $nn_y 1 "east"] nnn_x nnn_y
            if {[info exists map($nnn_x,$nnn_y)]} {
                set level +1
            } else {
                set level -1
            }
        }

        if {$name != ""} {
            switch $name {
                AA {
                    set map($x,$y) @
                }
                ZZ {
                    set map($x,$y) !
                }
                default {
                    set map($x,$y) ¤

                    if {[info exists matching($name)]} {
                        lassign [split $matching($name) ","] o_x o_y o_level
                        set tele($x,$y) $o_x,$o_y,$level,$name
                        set tele($o_x,$o_y) $x,$y,$o_level,$name
                    } else {
                        set matching($name) "$x,$y,$level"
                    }
                }
            }
        }
    }
}


# Traverse the map getting the number of steps to the destination
proc traverse_map {origin} {
    upvar 1 map map
    upvar 1 tele tele

    lassign [split [find_coord $origin] ","] x y

    set visited($x,$y) 0
    set unvisited [get_movements $x $y 1 0]
    set unvisited [lsort -integer -index 3 $unvisited]

    while {[llength $unvisited] != 0} {
        lassign [lindex $unvisited 0] c_x c_y c_z c_steps
        set unvisited [lreplace $unvisited 0 0]

        # Already visited
        if {[info exists visited($c_x,$c_y)]} {
            continue
        }

        set char $map($c_x,$c_y)
        if {$char == "!"} {
            return $c_steps
        }

        set new_unvisited [get_movements $c_x $c_y 1 $c_steps]
        set unvisited [list {*}$unvisited {*}$new_unvisited]
        set unvisited [lsort -integer -index 3 $unvisited]

        set visited($c_x,$c_y) $c_steps
    }
}

# Traverse the level map getting the number of steps to the destination
proc traverse_level_map {origin} {
    upvar 1 map map
    upvar 1 tele tele

    lassign [split [find_coord $origin] ","] x y

    set visited($x,$y,0) 0
    set unvisited [get_movements $x $y 0 0]
    set unvisited [lsort -integer -index 3 $unvisited]

    while {[llength $unvisited] != 0} {
        lassign [lindex $unvisited 0] c_x c_y c_z c_steps
        set unvisited [lreplace $unvisited 0 0]

        # Already visited
        if {[info exists visited($c_x,$c_y,$c_z)]} {
            continue
        }

        set char $map($c_x,$c_y)
        if {$char == "!" && $c_z == 0} {
            return $c_steps
        }

        set new_unvisited [get_movements $c_x $c_y $c_z $c_steps]
        set unvisited [list {*}$unvisited {*}$new_unvisited]
        set unvisited [lsort -integer -index 3 $unvisited]

        set visited($c_x,$c_y,$c_z) $c_steps
    }
}

parse_map

# DEBUG PRINT
#print [get_boundaries]
#foreach {k v} [array get tele] {
#    puts "$k: $v"
#}

puts "Least number of steps: [traverse_map @]"
puts "Least number of steps: [traverse_level_map @]"
