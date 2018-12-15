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

# Adding a cart to carts
# A cart is a list of:
#  y-coordinate
#  x-cooridnate
#  direction
#  turn in next intersection
#  collision status
proc add_cart {carts x y dir} {
    lappend carts [list $y $x $dir "l" 0]
}

# Returning the direction after a left turn
proc turnleft {dir} {
    switch $dir {
        r { return u }
        l { return d }
        d { return r }
        u { return l }
    }
}

# Returning the direction after a right turn
proc turnright {dir} {
    switch $dir {
        r { return d }
        l { return u }
        d { return l }
        u { return r }
    }
}

# Movement of a cart
proc move_cart {cart} {
    global map

    lassign $cart y x dir turns dead
    
    switch $dir {
        r { incr x }
        l { incr x -1 }
        d { incr y }
        u { incr y -1}
        default {
            puts "Strange direction"
            exit
        }
    }

    switch $map($x,$y) {
        / {
            switch $dir {
                r { set dir u }
                l { set dir d }
                d { set dir l }
                u { set dir r }
            }
        }
        \\ {
            switch $dir {
                r { set dir d }
                l { set dir u }
                d { set dir r }
                u { set dir l }
            }
        }
        + {
            switch $turns {
                l {
                    set dir [turnleft $dir]
                    set turns "s"
                }
                s {
                    set turns "r"
                }
                r {
                    set dir [turnright $dir]
                    set turns "l"
                }
                default {
                    puts "strange turns"
                    exit
                }
            }
        }
        - { }
        | { }
        default {
            puts "Strange track"
            exit
        }
    }
    return [list $y $x $dir $turns $dead]
}

# Check if there are any collisions among the carts
# Returns the collision cart indexes as a list
# If no collisions returns empty list
proc collision {carts} {
    set length [llength $carts]
    for {set i 0} {$i < $length} {incr i} {
        set first_cart [lindex $carts $i]
        lassign $first_cart fy fx fdir fturns fdead
        if {$fdead == 1} {
            continue
        }

        for {set j [expr $i + 1]} {$j < $length} {incr j} {
            set second_cart [lindex $carts $j]
            lassign $second_cart sy sx sdir sturns sdead
            if {$sdead == 1} {
                continue
            }

            if {$fx == $sx && $fy == $sy} {
                return [list $i $j]
            }
        }
    }
    return []
}

# Parsing of the inputs
# Carts ends up in the carts list
# And the map as an array with $x,$y as the key
set carts [list]
for {set y 0} {$y < [llength $indata]} {incr y} {
    set row [split [lindex $indata $y] ""]

    for {set x 0} {$x < [llength $row]} {incr x} {
        set char [lindex $row $x]

        switch $char {
            > {
                set carts [add_cart $carts $x $y "r"]
                set map($x,$y) "-"
            }
            < {
                set carts [add_cart $carts $x $y "l"]
                set map($x,$y) "-"
            }
            v {
                set carts [add_cart $carts $x $y "d"]
                set map($x,$y) "|"
            }
            ^ {
                set carts [add_cart $carts $x $y "u"]
                set map($x,$y) "|"
            }
            default {
                set map($x,$y) $char
            }
        }
    }
}

# Do movement of the carts
# Sorting the list will give the correct order of movements since
# the carts have their y-coordinate as the first index and the
# x-coordinate as the second one
while 1 {
    set carts [lsort $carts]
    for {set i 0} {$i < [llength $carts]} {incr i} {
        set cart [lindex $carts $i]
        set collided [lindex $cart 4]
        if {$collided == 1} {
            continue
        }
        set cart [move_cart $cart]
        set carts [lreplace $carts $i $i $cart]
        set collision_carts [collision $carts]
        if {$collision_carts != []} {
            lassign $collision_carts first second

            set cart1 [lindex $carts $first]
            set cart2 [lindex $carts $second]

            set cart1 [lreplace $cart1 4 4 1]
            set cart2 [lreplace $cart2 4 4 1]

            set carts [lreplace $carts $first $first $cart1]
            set carts [lreplace $carts $second $second $cart2]

            lassign $cart1 y x
            puts "Collision at: $x,$y"
        }
    }

    set count 0
    foreach cart $carts {
        set collided [lindex $cart 4]
        if {$collided == 0} {
            incr count
        }
    }
    
    if {$count == 0} {
        puts "No more carts"
        exit
    }
    
    if {$count == 1} {
        foreach cart $carts {
            lassign $cart y x dir turns collided
            if {$collided == 0} {
                puts "Last remaining cart is at: $x,$y"
                exit
            }
        }
    }
}
