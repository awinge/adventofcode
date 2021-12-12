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

# Proc for setting a value of a grid rectangle
proc set_grid {gridname x0 y0 x1 y1 value} {
    upvar 1 $gridname grid

    for {set x $x0} {$x <= $x1} {incr x} {
        for {set y $y0} {$y <= $y1} {incr y} {
            set grid($x,$y) $value
        }
    }
}

# Proc for toggeling a value of a grid rectangle
proc toggle_grid {gridname x0 y0 x1 y1 value} {
    upvar 1 $gridname grid

    for {set x $x0} {$x <= $x1} {incr x} {
        for {set y $y0} {$y <= $y1} {incr y} {
            if {![info exist grid($x,$y)]} {
                set grid($x,$y) 1
            } else {
                if {$grid($x,$y)} {
                    set grid($x,$y) 0
                } else {
                    set grid($x,$y) 1
                }
            }
        }
    }
}


# Parse the indata and use the procs above
foreach data $indata {
    if {[regexp {turn on ([0-9]*),([0-9]*) through ([0-9]*),([0-9]*)} $data match x0 y0 x1 y1]} {
        set_grid grid $x0 $y0 $x1 $y1 1
        continue
    }

    if {[regexp {turn off ([0-9]*),([0-9]*) through ([0-9]*),([0-9]*)} $data match x0 y0 x1 y1]} {
        set_grid grid $x0 $y0 $x1 $y1 0
        continue
    }

    if {[regexp {toggle ([0-9]*),([0-9]*) through ([0-9]*),([0-9]*)} $data match x0 y0 x1 y1]} {
        toggle_grid grid $x0 $y0 $x1 $y1 0
        continue
    }

    puts "Unparsed: $data"
}

# Count the number of lit lights
foreach {k v} [array get grid] {
    if {$v} {
        incr lit
    }
}

puts "Lit lights: $lit"


# Proc for incrementing a grid rectable with a value
# Smallest value allowed is zero
proc incr_grid {gridname x0 y0 x1 y1 value} {
    upvar 1 $gridname grid

    for {set x $x0} {$x <= $x1} {incr x} {
        for {set y $y0} {$y <= $y1} {incr y} {
            incr grid($x,$y) $value

            if {$grid($x,$y) < 0} {
                set grid($x,$y) 0
            }
        }
    }
}

array unset grid

# Parse the indata and use the proc above
foreach data $indata {
    if {[regexp {turn on ([0-9]*),([0-9]*) through ([0-9]*),([0-9]*)} $data match x0 y0 x1 y1]} {
        incr_grid grid $x0 $y0 $x1 $y1 1
        continue
    }

    if {[regexp {turn off ([0-9]*),([0-9]*) through ([0-9]*),([0-9]*)} $data match x0 y0 x1 y1]} {
        incr_grid grid $x0 $y0 $x1 $y1 -1
        continue
    }

    if {[regexp {toggle ([0-9]*),([0-9]*) through ([0-9]*),([0-9]*)} $data match x0 y0 x1 y1]} {
        incr_grid grid $x0 $y0 $x1 $y1 2
        continue
    }

    puts "Unparsed: $data"
}

# Calculate total brightness
foreach {k v} [array get grid] {
    incr brightness $v
}

puts "Total brightness: $brightness"
