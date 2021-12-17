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

if {![regexp {target area: x=([0-9-]*)\.\.([0-9-]*), y=([0-9-]*)\.\.([0-9-]*)} $indata match tminx tmaxx tminy tmaxy]} {
    puts "Failed to parse: $input"
    exit
}

# Proc for one step
# Returns a list of new values of x y xv and yv
proc step {x y xv yv} {
    incr x $xv

    if {$xv > 0} {
        incr xv -1
    } elseif {$xv < 0} {
        incr xv 1
    }

    incr y $yv
    incr yv -1

    return [list $x $y $xv $yv]
}


set maxy 0
# Loop through the plausable initial velocities
for {set init_xv 0} {$init_xv <= $tmaxx} {incr init_xv} {
    for {set init_yv $tminy} {$init_yv <= 600} {incr init_yv} {

        # Set the starting position
        set x 0
        set y 0
        set xv $init_xv
        set yv $init_yv

        # Keep track of maxy for this run and if we hit the target
        set local_maxy 0
        set hit 0
        while {$y > $tminy && $x < $tmaxx} {
            lassign [step $x $y $xv $yv] x y xv yv

            if {$y > $local_maxy} {
                set local_maxy $y
            }

            if {$x >= $tminx && $x <= $tmaxx && $y >= $tminy && $y <= $tmaxy} {
                set hit 1
                break
            }
        }

        # If it is a hit, then check the local maxy against the global one
        # and count the hit
        if {$hit} {
            incr hits

            if {$local_maxy > $maxy} {
                set maxy $local_maxy
            }
        }
    }

}

puts "Max y with hit: $maxy"
puts "Velocities with hit: $hits"
