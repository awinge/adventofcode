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

# Calculate the manhattan distance between two bots
proc manhattan {bot1 bot2} {
    set bot1 [lrange $bot1 0 2]
    set bot2 [lrange $bot2 0 2]

    return [expr [join [lmap a $bot1 b $bot2 { expr abs($a - $b) }] "+"]]
}

# Check if a bot is in range from another bot
proc bot_in_range {bot from_bot} {
    lassign $from_bot _x _y _z r
    if {[manhattan $bot $from_bot] <= $r} {
        return 1
    } else {
        return 0
    }
}

# Puts all nanobots in a list. Each bot is a list of x y z and radius
# Find out the nanobot with the largest signal radius
foreach data $indata {
    if {[regexp {pos=<([-\d]*),([-\d]*),([-\d]*)>, r=([\d]*)} $data _match x y z r]} {
        lappend bots [list $x $y $z $r]

        if {![info exists max_radius] || $r > $max_radius} {
            set max_radius $r
            set max_radius_bot [list $x $y $z $r]
        }
    }
}


# Find out how many nanobots that are in range
foreach bot $bots {
    if {[bot_in_range $bot $max_radius_bot] == 1} {
        incr range
    }
}

puts "The number of nanobots in range: $range"

# Initialize binary search
# The number of steps are hard-coded here to a nice number.
# However that can be calculated depending on the min and max values
set steps 26
set divider [expr pow(2.0,$steps)]
set div_bots [lmap bot $bots { lmap part $bot {expr round($part/$divider)} }]

foreach bot $div_bots {
    lassign $bot x y z
    if {![info exists minx] || $x < $minx} {
        set minx $x
    }
    if {![info exists miny] || $y < $miny} {
        set miny $y
    }
    if {![info exists minz] || $z < $minz} {
        set minz $z
    }
    if {![info exists maxx] || $x > $maxx} {
        set maxx $x
    }
    if {![info exists maxy] || $y > $maxy} {
        set maxy $y
    }
    if {![info exists maxz] || $z > $maxz} {
        set maxz $z
    }
}

while {$divider >= 1.0} {
    # Search for the maximum
    set max -1
    for {set x $minx} {$x <= $maxx} {incr x} {
        for {set y $miny} {$y <= $maxy} {incr y} {
            for {set z $minz} {$z <= $maxz} {incr z} {
                set range 0
                foreach bot $div_bots {
                    if {[bot_in_range [list $x $y $z] $bot] == 1} {
                        incr range
                    }
                }
                if {$range == $max} {
                    if {[manhattan [list 0 0 0] [list $x $y $z]] <
                        [manhattan [list 0 0 0] $sweetspot]} {
                        set sweetspot [list $x $y $z]
                    }
                }
                if {$range > $max} {
                    set max $range
                    set sweetspot [list $x $y $z]
                }
            }
        }
    }
    lassign $sweetspot x y z

    # Calculate new min and max values for the next iteration
    set minx [expr ($x * 2) - 2]
    set miny [expr ($y * 2) - 2]
    set minz [expr ($z * 2) - 2]
    set maxx [expr ($x * 2) + 2]
    set maxy [expr ($y * 2) + 2]
    set maxz [expr ($z * 2) + 2]

    # Calculate the values for the new divider
    set divider [expr $divider / 2]
    set div_bots [lmap bot $bots { lmap part $bot {expr round($part/$divider)} }]
}

puts "Manhattan distance to sweetspot: [manhattan [list 0 0 0] $sweetspot]"
