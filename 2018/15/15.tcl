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

# Creating the map and give G and E 200 HP
set y 0
foreach data $indata {
    set x 0
    foreach s [split $data ""] {
        if {$s == "G" || $s == "E"} {
            set map($x,$y) [list $s 200]
        } else {
            set map($x,$y) [list $s 0]
        }
        incr x
    }
    incr y
}

set maxx [expr $x - 1]
set maxy [expr $y - 1]
array set orig_map [array get map]

# Printing the map, used for debug and amusement
proc print {} {
    global maxx maxy
    global map

    for {set y 0} {$y <= $maxy} {incr y} {
        set hitpoints [list]
        for {set x 0} {$x <= $maxx} {incr x} {
            lassign $map($x,$y) terrain hp
            puts -nonewline $terrain
            if {$terrain == "G" || $terrain == "E"} {
                lappend hitpoints $hp
            }
        }
        if {$hitpoints != []} {
            puts "  [join $hitpoints ", "]"
        } else {
            puts ""
        }
    }
}

# Printint the range map, used for debug
proc print_range {} {
    global maxx maxy
    global map
    global range_map

    for {set y 0} {$y <= $maxy} {incr y} {
        for {set x 0} {$x <= $maxx} {incr x} {
            if {[info exists range_map($x,$y)]} {
                puts -nonewline $range_map($x,$y)
            } else {
                puts -nonewline [lindex $map($x,$y) 0]
            }
        }
        puts ""
    }
}

# Look for all units in order and create a new round
# which is returned a a list of coorinates
proc get_round {} {
    global maxx maxy
    global map

    for {set y 0} {$y <= $maxy} {incr y} {
        for {set x 0} {$x <= $maxx} {incr x} {
            switch [lindex $map($x,$y) 0] {
                E -
                G { lappend round [list $x $y] }
            }
        }
    }

    return $round
}

# Returns a list of all possile targets of a unit
proc get_all_targets {unit} {
    global maxx maxy
    global map

    switch [lindex $map([join $unit ,]) 0] {
        G { set target E }
        E { set target G }
    }

    set targets [list]
    for {set y 0} {$y <= $maxy} {incr y} {
        for {set x 0} {$x <= $maxx} {incr x} {
            if {[lindex $map($x,$y) 0] == $target} {
                lappend targets [list $x $y]
            }
        }
    }
    return $targets
}

# Get all adjacent coordinates from input position
# These will be returned as a list
# E.g. {1 1} => {{1 2} {2 1} {0 1} {1 0}}
# Reversed reading order

proc get_adjacent {pos} {
    lassign $pos cx cy

    foreach dir [list d r l u] {
        switch $dir {
            u {
                set nx $cx
                set ny [expr $cy - 1]
            }
            d {
                set nx $cx
                set ny [expr $cy + 1]
            }
            r {
                set nx [expr $cx + 1]
                set ny $cy
            }
            l {
                set nx [expr $cx - 1]
                set ny $cy
            }
        }
        lappend adjacent [list $nx $ny]
    }
    return $adjacent
}

# Get all possible positions to attack the input target
# These are returned a list
proc get_in_range {targets} {
    global map

    set in_range [list]
    foreach target $targets {
        foreach pos [get_adjacent $target] {
            if {[lindex $map([join $pos ,]) 0] == "."} {
                lappend in_range $pos
            }
        }
    }
    return $in_range
}

# Returns a list of all enemys in range of the unit
proc enemies_in_range {unit} {
    global map

    switch [lindex $map([join $unit ,]) 0] {
        G { set enemy E }
        E { set enemy G }
    }

    set enemies [list]
    foreach pos [get_adjacent $unit] {
        if {[lindex $map([join $pos ,]) 0] == $enemy} {
            lappend enemies $pos
        }
    }
    return $enemies
}

# Impementation of Dijkstras algoritm for creating a range map
# with a defined starting position as input
proc create_range_map {start} {
    global map
    global range_map

    if {[info exists range_map]} {
        array unset range_map
    }

    set open_list [list [list 0 {*}$start]]
    while {[llength $open_list] > 0} {
        # Sorting the open_list
        set open_list [lsort -integer -index 0 $open_list]

        set current [lindex $open_list 0]
        lassign $current cf cx cy
        set range_map($cx,$cy) $cf
        set nf [expr $cf + 1]


        foreach pos [get_adjacent [list $cx $cy]] {
            lassign $pos nx ny

            # Possible
            if {[lindex $map($nx,$ny) 0] == "."} {
                # Exists in closed list (range_map)
                if {[info exists range_map($nx,$ny)]} {
                    # Better path
                    if {$nf < $range_map($nx,$ny)} {
                        unset range_map($nx,$ny)
                        lappend open_list [list $nf $nx $ny]
                    }
                    continue
                }

                # Check if it is in the open list
                set found_in_open 0
                for {set i 0} {$i < [llength $open_list]} {incr i} {
                    lassign [lindex $open_list $i] of ox oy

                    # Found in open list
                    if {$ox == $nx && $oy == $ny} {
                        set found_in_open 1

                        # Better path found
                        if {$nf < $of} {
                            set open_list [lreplace $open_list $i $i]
                            lappend open_list [list $nf $nx $ny]
                        }
                        # It never exist twice so exit
                        break
                    }

                }

                if {$found_in_open == 0} {
                    lappend open_list [list $nf $nx $ny]
                }
            }
        }
        set open_list [lreplace $open_list 0 0]
    }
}

# Moving a unit according to the movement rules
proc move {unit target} {
    global map
    global range_map

    create_range_map $target

    foreach pos [get_adjacent $unit] {
        if {[info exists range_map([join $pos ,])]} {
            set steps $range_map([join $pos ,])

            # Check minimum number of steps <= makes the priority reverse
            # of the get_adjacent list above. I.e. priority up left right down
            if {![info exists min_steps] || $steps <= $min_steps} {
                set new_pos   $pos
                set min_steps $steps
            }
        }
    }

    set map([join $new_pos ,]) $map([join $unit ,])
    set map([join $unit ,])    [list . 0]

    return $new_pos
}

# Attack handling including boosting elves attack power
proc attack {target elves_boost} {
    global map

    lassign $map([join $target ,]) type hp

    incr hp -3
    if {$type == "G"} {
        incr hp -$elves_boost
    }

    if {$hp <= 0} {
        set map([join $target ,]) [list . 0]
        return 1
    } else {
        set map([join $target ,]) [list $type $hp]
        return 0
    }
}

# Resolving the war that has been set up in the map
# Supports boosting elves attack power with the input
# Setting debug to 1 will print the map after each round
proc resolve_war {elves_boost} {
    global map
    global range_map
    global debug

    set round [get_round]
    set round_counter 0
    while 1 {
        if {![info exists round] || [llength $round] == 0} {
            set round [get_round]
            incr round_counter
            if {[info exists debug] && $debug == 1} {
                puts "After round $round_counter:"
                print
            }
        }

        set unit [lindex $round 0]

        # Movement
        if {[enemies_in_range $unit] == []} {
            set all_targets [get_all_targets $unit]

            # Cannot find any targets, the war is over
            if {[llength $all_targets] == 0} {
                if {[info exists debug] && $debug == 1} {
                    puts "End:"
                    print
                }
                return $round_counter
            }
            set in_range [get_in_range $all_targets]

            create_range_map $unit
            set reachable_in_range [list]
            foreach i $in_range {
                lassign $i x y

                if {[info exists range_map($x,$y)]} {
                    lappend reachable_in_range [list $range_map($x,$y) $x $y]
                }
            }
            if {[llength $reachable_in_range] > 0} {
                set reachable_in_range [lsort -integer -index 1 $reachable_in_range]
                set reachable_in_range [lsort -integer -index 2 $reachable_in_range]
                set reachable_in_range [lsort -integer -index 0 $reachable_in_range]

                set target [lrange [lindex $reachable_in_range 0] 1 2]

                set unit [move $unit $target]
            }
        }

        # Attack
        set enemies [enemies_in_range $unit]
        if {$enemies != []} {
            set sort_enemies [list]
            foreach enemy $enemies {
                lappend sort_enemies [list {*}$enemy [lindex $map([join $enemy ,]) 1]]
            }

            set sort_enemies [lsort -integer -index 0 $sort_enemies]
            set sort_enemies [lsort -integer -index 1 $sort_enemies]
            set sort_enemies [lsort -integer -index 2 $sort_enemies]

            set target [lrange [lindex $sort_enemies 0] 0 1]

            set unit_died [attack $target $elves_boost]

            # Remove the unit from the round list
            if {$unit_died == 1} {
                if {$elves_boost != 0 && [lindex $map([join $unit ,]) 0] == "G"} {
                    return -1
                }
                for {set i 0} {$i < [llength $round]} {incr i} {
                    if {$target == [lindex $round $i]} {
                        set round [lreplace $round $i $i]
                        break
                    }
                }
            }
        }
        set round [lreplace $round 0 0]
    }
}

# Counts the total HP in the map
proc count_total_hp {} {
    global map

    foreach {key value} [array get map] {
        lassign $value terrain hp

        incr total_hp $hp
    }
    return $total_hp
}

set round_counter [resolve_war 0]
puts "Outcome: [expr $round_counter * [count_total_hp]]"

array set map [array get orig_map]

while 1 {
    array set map [array get orig_map]
    incr boost
    set round_counter [resolve_war $boost]

    if {$round_counter != -1} {
        break
    }
}

puts "Outcome with elves attack power of [expr 3 + $boost]: [expr $round_counter * [count_total_hp]]"
