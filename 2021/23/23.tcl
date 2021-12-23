#!/usr/bin/tclsh

# Testinput
set at [list B A]
set bt [list C D]
set ct [list B C]
set dt [list D A]

# Input part 1
set a1 [list B C]
set b1 [list B A]
set c1 [list D A]
set d1 [list D C]

# Input part 2
set a2 [list B D D C]
set b2 [list B C B A]
set c2 [list D B A A]
set d2 [list D A C C]

set hall [list . . X . X . X . X . .]


# Return the cost of a move
proc cost {amp} {
    switch $amp {
        A { set mcost 1    }
        B { set mcost 10   }
        C { set mcost 100  }
        D { set mcost 1000 }
        default {
            puts "No cost of $amp"
            exit
        }
    }
}

# Get a list of valid moves from a room
# hall_index is where the room enters the hall
#
# The list returned is {cost, from, to}
proc get_room_moves {room_name room hall hall_index} {
    set possible {}

    # Check that you are allowed to move from the room
    foreach d $room {
        if {$d != "." && $d != $room_name} {
            set move 1
        }
    }

    # Return an empty list if you were not allowed
    if {![info exist move]} {
        return []
    }

    # Check who to move from the room (the first non-empty spot)
    for {set d 0} {$d < [llength $room]} {incr d} {
        set mover [lindex $room $d]

        if {$mover != "."} {
            break
        }
    }

    # You can either to to the left or rigth when you leave the room

    # Try to the left, stop when something is blocking
    set steps $d
    for {set i $hall_index} {$i >= 0} {incr i -1} {
        incr steps
        switch [lindex $hall $i] {
            "X" { continue }
            "." {
                lappend possible [list [expr [cost $mover] * $steps] "[string tolower $room_name]$d" "h$i"]
            }
            default { break }
        }
    }

    # Try to the right, stop when something is blocking
    set steps $d
    for {set i $hall_index} {$i < [llength $hall]} {incr i} {
        incr steps
        switch [lindex $hall $i] {
            "X" { continue }
            "." {
                lappend possible [list [expr [cost $mover] * $steps] "[string tolower $room_name]$d" "h$i"]
            }
            default { break }
        }
    }

    return $possible
}

# Proc for getting the room spot you can move into
# Return -1 if you should not move into the room
# Otherwise return the spot in the room that you shall move into
proc get_room_spot {room_name room} {
    for {set i [expr [llength $room] -1]} {$i >= 0} {incr i -1} {
        if {[lindex $room $i] == "."} {
            return $i
        }
        if {[lindex $room $i] == $room_name} {
            continue
        }

        return -1
    }
    return -1
}


# Proc for getting the number of steps to take in the hallway
# to get to your room. If it is not possible to reach your
# room return -1
proc get_hall_steps {hall from} {
    set mover [lindex $hall $from]

    # These are the targets in the hall
    switch $mover {
        "A" { set goal 2 }
        "B" { set goal 4 }
        "C" { set goal 6 }
        "D" { set goal 8 }
    }

    # In which direction should we go
    if {$goal > $from} {
        set inc 1
    } else {
        set inc -1
    }

    # Start going checking for obstacles
    set steps 1
    for {set i [expr $from + $inc]} {$i != $goal} {incr i $inc} {
        incr steps
        switch [lindex $hall $i] {
            "X" { continue }
            "." { continue }
            default { break }
        }
    }

    if {$i == $goal} {
        return $steps
    } else {
        return -1
    }
}

# Proc for getting all the possible movements from the hall and
# into the rooms.
#
# The list returned is {cost, from, to}
proc get_hall_moves {a b c d hall} {
    # If you should move into a room move to this spot
    set aspot [get_room_spot A $a]
    set bspot [get_room_spot B $b]
    set cspot [get_room_spot C $c]
    set dspot [get_room_spot D $d]

    set possible {}

    # Try all hall positions
    for {set i 0} {$i < [llength $hall]} {incr i} {
        set mover [lindex $hall $i]
        switch $mover {
            "X" { continue }
            "." { continue }
            default {
                # Found a possible mover
                set room_spot [set [string tolower $mover]spot]
                set hall_steps [get_hall_steps $hall $i]

                # Is it possible to move into the room and possible to move in the hallway
                if {$room_spot != -1 && $hall_steps != -1} {
                    set steps [expr $room_spot + 1 + $hall_steps]
                    lappend possible [list [expr [cost $mover] * $steps] "h$i" "[string tolower $mover]$room_spot"]
                }
            }
        }
    }
    return $possible
}

# Proc for getting all possible moves
#
# The list returned is {cost, from, to}
proc possible_moves {a b c d hall} {
    set possible {}
    set possible [list {*}$possible {*}[get_room_moves A $a $hall 2]]
    set possible [list {*}$possible {*}[get_room_moves B $b $hall 4]]
    set possible [list {*}$possible {*}[get_room_moves C $c $hall 6]]
    set possible [list {*}$possible {*}[get_room_moves D $d $hall 8]]
    set possible [list {*}$possible {*}[get_hall_moves $a $b $c $d $hall]]

    return $possible
}

# Proc for done critera
# I.e. only A in room A etc.
proc done {a b c d} {
    foreach i $a { if {$i != "A"} { return 0 }}
    foreach i $b { if {$i != "B"} { return 0 }}
    foreach i $c { if {$i != "C"} { return 0 }}
    foreach i $d { if {$i != "D"} { return 0 }}

    return 1
}

# Proc for returning the least cost of getting to the done critera.
# Test all possibilies with memoization
proc get_least_cost {a b c d hall} {
    global memo

    # Check value in memo
    if {[info exist memo($a,$b,$c,$d,$hall)]} {
        return $memo($a,$b,$c,$d,$hall)
    }

    # Check if done
    if {[done $a $b $c $d]} {
        return 0
    }

    # Get all possible moves
    set possible_moves [possible_moves $a $b $c $d $hall]

    # If no moves left return a bit number
    if {[llength $possible_moves] == 0} {
        return [expr int(1e7)]
    }

    # Foreach possible move create a list of costs
    foreach move $possible_moves {
        set na $a
        set nb $b
        set nc $c
        set nd $d
        set nh $hall

        lassign $move mc mf mt

        regexp {([a-z])([0-9]*)} $mf match floc fi
        regexp {([a-z])([0-9]*)} $mt match tloc ti

        lset n$tloc $ti [lindex [set n$floc] $fi]
        lset n$floc $fi "."

        lappend costs [expr $mc + [get_least_cost $na $nb $nc $nd $nh]]
    }

    # Get the lowest cost, add in memo and return the value
    set lowest_cost [expr min([join $costs ,])]
    set memo($a,$b,$c,$d,$hall) $lowest_cost
    return $lowest_cost
}

puts "Least cost: [get_least_cost $a1 $b1 $c1 $d1 $hall]"
puts "Least cost: [get_least_cost $a2 $b2 $c2 $d2 $hall]"
