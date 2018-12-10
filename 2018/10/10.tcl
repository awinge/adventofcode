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

# Parsing indata creating points list
foreach data $indata {
    regexp {position=< *([-0-9]*), *([-0-9]*)> velocity=< *([-0-9]*), *([-0-9]*)>} $data _match x y vx vy
    lappend points [list $x $y $vx $vy]
}

# Returning a list of min/max values of x and y
proc minmax_xy {points} {
    foreach point $points {
        lassign $point x y vx vy
        if {![info exists minx] || $x < $minx} {
            set minx $x
        }
        if {![info exists miny] || $y < $miny} {
            set miny $y
        }
        if {![info exists maxx] || $x > $maxx} {
            set maxx $x
        }
        if {![info exists maxy] || $y > $maxy} {
            set maxy $y
        }
    }
    return [list $minx $maxx $miny $maxy]
}
    
# Printing function for the points 
proc print {points} {
    lassign [minmax_xy $points] minx maxx miny maxy

    for {set i $miny} {$i <= $maxy} {incr i} {
        lappend grid [lrepeat [expr $maxx - $minx + 1] .]
    }

    foreach point $points {
        lassign $point x y vx vy
        lset grid [expr $y - $miny] [expr $x - $minx] #
    }
    
    foreach row $grid {
        puts [join $row ""]
    }
}

# Update all ponits according to their velocity
# Returns a new list of points
proc update {points} {
    foreach point $points {
        lassign $point x y vx vy
        set x [expr $x + $vx]
        set y [expr $y + $vy]

        lappend new_points [list $x $y $vx $vy]
    }

    return $new_points
}

# Returns the size of the grid
proc size {points} {
    lassign [minmax_xy $points] minx maxx miny maxy

    return [expr ($maxx - $minx) * ($maxy - $miny)]
}

# Searching for the smallest grid
set second 0
while {1} {
    set new_points [update $points]

    # Looking for when the grid starts to become larger again
    if {[size $new_points] > [size $points]} {
        break;
    }
    set points $new_points
    incr second
}

puts "At second: $second"
print $points
