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

# Proc to find min and max x and y
proc minmax_xy {x y minx maxx miny maxy} {
    upvar 1 $minx min_x
    upvar 1 $maxx max_x
    upvar 1 $miny min_y
    upvar 1 $maxy max_y

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

# Parsing indata creating the map.
# Also runs all data through proc above
foreach data $indata {
    if {[regexp {x=([\d]*), y=([\d]*)\.\.([\d]*)} $data _match x ymin ymax]} {
        for {set y $ymin} {$y <= $ymax} {incr y} {
            set map($x,$y) #
            
            minmax_xy $x $y minx maxx miny maxy
        }
    }

    if {[regexp {y=([\d]*), x=([\d]*)\.\.([\d]*)} $data _match y xmin xmax]} {
        for {set x $xmin} {$x <= $xmax} {incr x} {
            set map($x,$y) #

            minmax_xy $x $y minx maxx miny maxy
        }
    }
}

# Print the map, only for debugging
proc print {} {
    global map
    global minx maxx miny maxy

    for {set y $miny} {$y <= $maxy} {incr y} {
        for {set x [expr $minx - 1]} {$x <= [expr $maxx + 1]} {incr x} {
            if {![info exists map($x,$y)]} {
                puts -nonewline "."
            } else {
                puts -nonewline $map($x,$y)
            }
        }
        puts ""
    }
}

# Finding the bottom starting with input coordinates
# Returns new coordinates as a list
# If no bottom found (off the map) return {0 0}
proc find_bottom {x y} {
    global map
    global minx maxx miny maxy

    if {$y < $miny} {
        set y $miny
    }

    if {$y > $maxy} {
        return [list 0 0]
    }
    
    if {![info exists map($x,$y)]} {
        set map($x,$y) |
        return [find_bottom $x [expr $y + 1]]
    }
    
    switch $map($x,$y) {
        | { return [find_bottom $x [expr $y + 1]] }
        ~ { return [list $x [expr $y - 1]] }
        # { return [list $x [expr $y - 1]] }
    }
}

# Flow water either to the right or left
# Returning the coordinates of a wall hit or
#           the coordinates of the drop off the edge
proc flow {x y dir} {
    global map

    switch $dir {
        left { set newx [expr $x - 1] }
        right { set newx [expr $x + 1] }
    }
    if {![info exists map($newx,$y)]} {
        set left .
    } else {
        set left $map($newx,$y)
    }

    # Found a wall, return
    if {$left == "#"} {
        set map($x,$y) |
        return [list $newx $y]
    }
    
    if {![info exists map($x,[expr $y + 1])]} {
        set down .
    } else {
        set down $map($x,[expr $y + 1])
    }

    # Solid ground below
    if {$down == "#" || $down == "~"} {
        set map($x,$y) |
        return [flow $newx $y $dir]
    } else {
        return [list $x $y]
    }
}

# Fill the map with water in rest between minx and maxx
proc fill {minx maxx y} {
    global map

    for {set i [expr $minx + 1]} {$i < $maxx} {incr i} {
        set map($i,$y) ~
    }
}

proc pour {x y} {
    global map
    
    lassign [find_bottom $x $y] x y

    if {$x == 0 && $y == 0} {
        return 
    }

    lassign [flow $x $y "left"] leftx lefty
    lassign [flow $x $y "right"] rightx righty

    # Fill with water in rest between the two walls
    if {[info exists map($rightx,$righty)] && $map($rightx,$righty) == "#" &&
        [info exists map($leftx,$lefty)] && $map($leftx,$lefty) == "#"} {
        fill $leftx $rightx $righty
        pour $x [expr $y - 1]
    }

    # Do recursive pouring off the edge
    if {![info exists map($rightx,$righty)]} {
        pour $rightx $righty
    }

    # Do recursive pouring off the edge
    if {![info exists map($leftx,$lefty)]} {
        pour $leftx $lefty
    }
}

set wellx 500
set welly 0

pour $wellx $welly

# Go throught the map looking for water
foreach {key value} [array get map] {
    if {$value == "|" || $value == "~"} {
        incr water_reach
    }

    if {$value == "~"} {
        incr water_resting
    }
}

puts "Square meters the water can reach: $water_reach"
puts "Square meters of water in rest: $water_resting"


