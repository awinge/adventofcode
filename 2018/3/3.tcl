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

# Initializing fabric (assuming 1000x1000 maxsize)
for {set x 0} {$x < 1000} {incr x} {
    set listy []
    for {set y 0} {$y < 1000} {incr y} {
        lappend listy "."
    }
    lappend fabric $listy
}

# Plotting in all IDs
foreach data $indata {
    if {[regexp {.([0-9]*) @ ([0-9]*),([0-9]*): ([0-9]*)x([0-9]*)} $data _all id posx posy sizex sizey]} {
        lappend parsed [list $id $posx $posy [expr $posx + $sizex] [expr $posy + $sizey]]
        
        for {set x $posx} {$x < [expr $posx + $sizex]} {incr x} {
            set listy [lindex $fabric $x]
            for {set y $posy} {$y < [expr $posy + $sizey]} {incr y} {
                if {[lindex $listy $y] != "."} {
                    set listy [lreplace $listy $y $y "X"]
                } else {
                    set listy [lreplace $listy $y $y $id]
                }
            }
            set fabric [lreplace $fabric $x $x $listy]
        }
    }
}

# Count square inches overlap
set counter 0
foreach col $fabric {
    foreach dot $col {
        if {$dot == "X"} {
            incr counter
        }
    }
}
puts "Square inches overlap: $counter"

# Check which ID is still intact  
foreach data $indata {
    if {[regexp {.([0-9]*) @ ([0-9]*),([0-9]*): ([0-9]*)x([0-9]*)} $data _all id posx posy sizex sizey]} {
        lappend parsed [list $id $posx $posy [expr $posx + $sizex] [expr $posy + $sizey]]

        set found 1
        for {set x $posx} {$x < [expr $posx + $sizex]} {incr x} {
            set listy [lindex $fabric $x]
            for {set y $posy} {$y < [expr $posy + $sizey]} {incr y} {
                if {[lindex $listy $y] != $id} {
                    set found 0
                    break
                }
            }
            if {$found == 0} {
                break;
            }
        }

        if {$found == 1} {
            puts "$id does not overlap"
            break
        }
    }
}
