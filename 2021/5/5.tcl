#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	#lappend indata [regexp -inline -all -- {\S+} $row]
	lappend indata $row
    }
}

# Create map for part one and map2 for part2
foreach data $indata {
    if {[regexp {([0-9]*),([0-9]*) -> ([0-9]*),([0-9]*)} $data match x1 y1 x2 y2]} {

        # Figure out what of the x values are larger and if that means
        # that we flip the x axis.
        if {$x1 < $x2} {
            set sx $x1
            set lx $x2
            set xflip 0
        } else {
            set sx $x2
            set lx $x1
            set xflip 1
        }

        # Same for y
        if {$y1 < $y2} {
            set sy $y1
            set ly $y2
            set yflip 0
        } else {
            set sy $y2
            set ly $y1
            set yflip 1
        }

        # If x are the same loop over y
        if {$sx == $lx} {
            for {set y $sy} {$y <= $ly} {incr y} {
                incr map($sx,$y)
                incr map2($sx,$y)
            }
        # If y are the same loop over x
        } elseif {$sy == $ly} {
            for {set x $sx} {$x <= $lx} {incr x} {
                incr map($x,$sy)
                incr map2($x,$sy)
           }
        } else {
            # Iterate over the diagonal line taking into consideration if
            # the axis were flipped. Both being flipped is the same as no flip
            for {set i 0} {$i <= $lx - $sx} {incr i} {
                if {[expr $xflip + $yflip] != 1} {
                    incr map2([expr $sx + $i],[expr $sy + $i])
                } else {
                    incr map2([expr $sx + $i],[expr $ly - $i])
                }
            }
        }
    }
}

# Count the points for first map
set points 0
foreach {k v} [array get map] {
    if {$v >= 2} {
        incr points
    }
}

puts "Points: $points"

# Count the points for second map
set points 0
foreach {k v} [array get map2] {
    if {$v >= 2} {
        incr points
    }
}

puts "Points: $points"
