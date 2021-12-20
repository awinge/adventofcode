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

# Get the algorithm
set alg [lindex $indata 0]
set indata [lreplace $indata 0 0]

# Parse the indata and create the image array
set y 0
foreach data $indata {
    set x 0

    foreach p [split $data ""] {
        set image($x,$y) $p
        incr x
    }
    incr y
}

# Needed to know the boundaries
set maxx [expr $x -1]
set maxy [expr $y -1]

# Print image for debug purposes
proc print {image_name} {
    upvar 1 $image_name image

    set y 0
    while {[info exist image(0,$y)]} {
        set x 0
        while {[info exist image($x,0)]} {
            puts -nonewline $image($x,$y)
            incr x
        }
        puts ""
        incr y
    }
}

# Proc for getting the index to use for the algorithm
#
# Check the surrounding pixels and create binary representation
# and parse it as deciamal for the return
proc get_index {image_name x y} {
    upvar 1 $image_name image

    set dx { -1  0  1 -1  0  1 -1  0  1}
    set dy { -1 -1 -1  0  0  0  1  1  1}

    for {set i 0} {$i < [llength $dx]} {incr i} {
        set cx [expr $x + [lindex $dx $i]]
        set cy [expr $y + [lindex $dy $i]]

        if {[info exists image($cx,$cy)] && $image($cx,$cy) == "#"} {
            append result 1
        } else {
            append result 0
        }
    }
    return [expr 0b$result]
}

# Proc for enhancing
#
# Do one step of enhancement with boarder extra around the image
# Align the new image so it starts at (0,0)
# Update maxx and maxy
proc enhance {image_name alg boarder} {
    upvar 1 $image_name image

    global maxx
    global maxy

    for {set y [expr -$boarder]} {$y <= $maxy + $boarder} {incr y} {
        for {set x [expr -$boarder]} {$x <= $maxx + $boarder} {incr x} {
            set new_image([expr $x + $boarder],[expr $y + $boarder]) [string index $alg [get_index image $x $y]]
        }
    }

    array unset image
    array set image [array get new_image]

    incr maxx [expr 2 * $boarder]
    incr maxy [expr 2 * $boarder]
}

# Prof for counting the number of lit pixels in the image
proc count_lit {image_name} {
    upvar 1 $image_name image

    set result 0
    foreach {k v} [array get image] {
        lassign [split $k ","] x y

        if {$v == "#"} {
            incr result
        }
    }
    return $result
}

# Dual enhancement steps
for {set i 0} {$i < 25} {incr i} {
    # First step will invert all pixels outside the image
    # So a sold boarder of 2 pixels are made (1 extra for the actual image)
    enhance image $alg 3

    # Second step will invert all pixels outside the iamge back (in infinity)
    # But it will leave some residue in the finite case, which is removed
    # by shrinking the image one step
    enhance image $alg -1

    if {$i == 0} {
        puts "Lit pixels after 2 enhancements: [count_lit image]"
    }
}

puts "Lit pixels after 50 enhancements: [count_lit image]"
