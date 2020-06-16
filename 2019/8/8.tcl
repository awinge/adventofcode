#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	lappend indata [regexp -inline -all -- {\S+} $row]
    }
}

set x_pixels 25
set y_pixels 6
set image_pixels [expr $x_pixels * $y_pixels]

set pixel_count 0
set zeroes      0
set ones        0 
set twos        0

# Iterate over pixels counting zeroes ones and twos.
# Also save the images as lists in a list (images)
foreach pixel [split $indata ""] {
    incr pixel_count

    lappend image $pixel
    switch $pixel {
        0 {
            incr zeroes
        }
        1 {
            incr ones
        }
        2 {
            incr twos
        }
    }

    if {$pixel_count == $image_pixels} {
        if {![info exists min_zeroes] || $zeroes < $min_zeroes} {
            set min_zeroes $zeroes
            set ones_min   $ones
            set twos_min   $twos
        }
        set pixel_count 0
        set zeroes      0
        set ones        0 
        set twos        0

        lappend images $image
        set image {}
    }
}

puts "number of 1 digites multplied by number of 2 digits: [expr $ones_min * $twos_min]"

# Set the top image as result
set image_result [lindex $images 0]

# Iterate over the rest of the images compiling the resulting image
for {set i 1} {$i < [llength $images]} {incr i} {
    set image_result [lmap a $image_result b [lindex $images $i] { 
        if {$a == 2} {
            set b
        } else {
            set a
        }
    }]
}

# Simple print function (white = "*" and black = " ")
proc print_image {image x_pixels} {
    set x 0
    foreach pixel $image {
        incr x
        if {$pixel == 0} {
            puts -nonewline " "
        } else {
            puts -nonewline "*"
        }
        if {$x == $x_pixels} {
            puts ""
            set x 0
        }
    }
}

puts "\nThis is the resulting image:"
print_image $image_result $x_pixels
