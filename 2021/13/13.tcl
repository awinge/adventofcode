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

# Parse the input
foreach data $indata {

    # This is a dot
    if {[regexp {([0-9]*),([0-9]*)} $data match x y]} {
        set paper($x,$y) 1
    }

    # This is a folding intruction
    if {[regexp {fold along (x|y)=([0-9]*)} $data match fold where]} {

        # Go through all the dots on the paper
        foreach {k v} [array get paper] {
            lassign [split $k ","] x y

            # Which direction is the fold
            switch $fold {
                x {
                    if {$x < $where} {
                        set folded_paper($x,$y) 1
                    } elseif {$x > $where} {
                        set folded_paper([expr $where - ($x - $where)],$y) 1
                    }
                }
                y {
                    if {$y < $where} {
                        set folded_paper($x,$y) 1
                    } elseif {$y > $where} {
                        set folded_paper($x,[expr $where - ($y - $where)]) 1
                    }
                }
            }
        }

        # Need to unset the paper first otherwise new points will be
        # just be added to the old paper
        array unset paper
        array set paper [array get folded_paper]
        array unset folded_paper
    }
}

# Proc for getting the min and max x and y
# returned as a list [minx maxx miny maxy]
proc get_min_max {papername} {
    upvar 1 $papername paper

    foreach {k v} [array get paper] {
        lassign [split $k ","] x y

        lappend xs $x
        lappend ys $y
    }

    set xs [lsort -incr -integer $xs]
    set ys [lsort -incr -integer $ys]

    return [list [lindex $xs 0] [lindex $xs end] [lindex $ys 0] [lindex $ys end]]
}


# Get the min and max
lassign [get_min_max paper] minx maxx miny maxy

# Print the answer
for {set y $miny} {$y <= $maxy} {incr y} {
    for {set x $minx} {$x <= $maxx} {incr x} {
        if {[info exist paper($x,$y)]} {
            puts -nonewline "*"
        } else {
            puts -nonewline " "
        }
    }
    puts ""
}
