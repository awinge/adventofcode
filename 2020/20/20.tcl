#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Get the rows into a list
foreach row [split $fd "\n"] {
    lappend indata $row
}

# Parsing the tiles
# Creating
foreach data $indata {
    # Set new tile ID
    if {[regexp {Tile ([0-9]+):} $data match id]} {
        continue
    }

    # Get the tile rows into an image
    if {[regexp {([.#]+)} $data match image_row]} {
        lappend image $image_row
        continue
    }

    # Empty line => store current tile and reset image
    if {$data == ""} {
        if {[info exist image]} {
            set tiles($id) $image
            unset image
        }
        continue
    }

    puts "Unparsed: $data"
}

# Handling last image, Store if no empty line at the end
if {[info exist image]} {
    set tiles($id) $image
    unset image
}


# Convert an edge into an integer
# Binary to decimal conversion '#' = 1, all other = 0
proc edge_to_num {edge} {
    set bin 0
    set num 0

    foreach char [lreverse [split $edge ""]] {
        if {$char == "#"} {
            incr num [expr int(pow(2,$bin))]
        }
        incr bin
    }
    return $num
}

# Create an array "edges" indexed with the tile number.
# Containing the edge_to_num converted value for each edge,
# as well as the reversed edge edge_to_num converted value
# The order of the content is:
# {{top top_rev} {right right_rev} {bottom bottom_rev} {left left_rev}}
foreach {k v} [array get tiles] {
    # Get the edges
    set top [lindex $v 0]
    set bottom [lindex $v [expr [llength $v] - 1]]
    set left ""
    set right ""
    foreach row $v {
        set left "$left[string index $row 0]"
        set right "$right[string index $row [expr [string length $row] - 1]]"
    }

    # Store the edge_to_num converted values
    lappend edges($k) [list [edge_to_num $top]    [edge_to_num [string reverse $top]]]
    lappend edges($k) [list [edge_to_num $right]  [edge_to_num [string reverse $right]]]
    lappend edges($k) [list [edge_to_num $bottom] [edge_to_num [string reverse $bottom]]]
    lappend edges($k) [list [edge_to_num $left]   [edge_to_num [string reverse $left]]]
}

# Rotates the list of edges clockwise
proc rotate_edges {edges} {
    lassign $edges top right bottom left

    set new_top    [lreverse $left]
    set new_right  $top
    set new_bottom [lreverse $right]
    set new_left   $bottom

    return [list $new_top $new_right $new_bottom $new_left]
}

# Flip the list of edge vertically
proc flip_edges {edges} {
    lassign $edges top right bottom left

    set new_top    $bottom
    set new_right  [lreverse $right]
    set new_bottom $top
    set new_left   [lreverse $left]

    return [list $new_top $new_right $new_bottom $new_left]
}

# Get possible placements from an existing image
# Returns a list {x0 y0 x1 y1 x2 y2...}
# where x<n> y<n> is a valid placement of a tile
proc get_valid_placements {image} {
    array set array_image $image

    foreach {k v} $image {
        lassign [split $k ","] x y

        foreach {dx dy} {0 1  0 -1  1 0  -1 0} {
            set newx [expr $x + $dx]
            set newy [expr $y + $dy]

            if {![info exist array_image($newx,$newy)]} {
                lappend possible $newx $newy
            }
        }
    }
    return $possible
}

# Checks if a edges representation of a tile fits at coordinates (x,y) in an existing image
# edges - {{top top_rev} {right right_rev} {bottom bottom_rev} {left left_rev}}
# x     - int
# y     - int
# image - image array in list representation
proc fits {edges x y image} {
    # Get the relavant edges fromt the edges (ignore the reverse ones)
    set edges_top    [lindex $edges 0 0]
    set edges_right  [lindex $edges 1 0]
    set edges_bottom [lindex $edges 2 0]
    set edges_left   [lindex $edges 3 0]

    # Recreate the image array (array_image)
    array set array_image $image

    # Check all neighbours in the image
    foreach {dx dy} {0 1  0 -1  1 0  -1 0} {
        set neighbour_x [expr $x + $dx]
        set neighbour_y [expr $y + $dy]

        if {[info exist array_image($neighbour_x,$neighbour_y)]} {
            set neighbour_top    [lindex $array_image($neighbour_x,$neighbour_y) 1 0 0]
            set neighbour_right  [lindex $array_image($neighbour_x,$neighbour_y) 1 1 0]
            set neighbour_bottom [lindex $array_image($neighbour_x,$neighbour_y) 1 2 0]
            set neighbour_left   [lindex $array_image($neighbour_x,$neighbour_y) 1 3 0]

            # Check fit to the right
            if {$dx == 1 && $edges_right != $neighbour_left} {
                return 0
            }

            # Check fit to the left
            if {$dx == -1 && $edges_left != $neighbour_right} {
                return 0
            }

            # check fit below
            if {$dy == 1 && $edges_bottom != $neighbour_top} {
                return 0
            }

            # check fit above
            if {$dy == -1 && $edges_top != $neighbour_bottom} {
                return 0
            }
        }
    }

    return 1
}

# Iterative placement of tiles
# edges: list representation of the edges array
#        {tile_id {{top top_rev} {right right_rev} {bottom bottom_rev} {left left_rev}}}
# placement: list representation of the already done placements
#        {x,y {tile_id {{top top_rev} {right right_rev} {bottom bottom_rev} {left left_rev}}} flip rotations}
#        flip      - tile was flipped to fit
#        rotations - how many rotations to fit
# Returns list representation of the placement array
proc place {edges placement} {
    # Recreate the placement array
    array set array_placement $placement

    # If no edges left to place, return the placement.
    if {[llength $edges] == 0} {
        return $placement
    }

    # If no edges have been placed. Place the first at coordinates (0,0)
    # and iterate with the placed tile removed from the edges list
    if {[llength $placement] == 0} {
        lassign $edges pk pv
        set array_placement(0,0) [list $pk $pv 0 0]
        set edges [lreplace $edges 0 1]
        return [place $edges [array get array_placement]]
    }

    # Try all valid placements
    foreach {x y} [get_valid_placements $placement] {
        set piece_index 0

        # Try with all edges
        foreach {pk pv} $edges {
            set cv $pv

            # Try not flipped and flipped
            foreach flips {0 1} {

                # Try all rotations
                foreach rotates {0 1 2 3} {

                    # If it fits place the edge, with flip and rotation values, at the current
                    # valid placement and iterate with the placed edge removed from the list
                    if {[fits $cv $x $y $placement]} {
                        set array_placement($x,$y) [list $pk $cv $flips $rotates]
                        set edges [lreplace $edges $piece_index [expr $piece_index + 1]]
                        return [place $edges [array get array_placement]]
                    }

                    set cv [rotate_edges $cv]
                }
                set cv [flip_edges $cv]
            }
            incr piece_index 2
        }
    }
}

# Get the boundaries for the a list representation of a grid
# grid - list representation of the grid array
proc get_min_max {grid} {
    upvar 1 minx minx
    upvar 1 miny miny
    upvar 1 maxx maxx
    upvar 1 maxy maxy

    set minx 0
    set miny 0
    set maxx 0
    set maxy 0
    foreach {k v} $grid {
        lassign [split $k ","] x y

        set minx [expr min($minx, $x)]
        set maxx [expr max($maxx, $x)]
        set miny [expr min($miny, $y)]
        set maxy [expr max($maxy, $y)]
    }
}

# Get product of tile ID of all four corners
proc get_corner_product {placement} {
    # Get placement boundaries
    get_min_max $placement

    # Recreate the placement array for easy access
    array set array_placement $placement

    # Get the tile id of the four corners of the placement
    set tl [lindex $array_placement($minx,$miny) 0]
    set tr [lindex $array_placement($maxx,$miny) 0]
    set bl [lindex $array_placement($minx,$maxy) 0]
    set br [lindex $array_placement($maxx,$maxy) 0]

    return [expr $tl * $tr * $bl * $br]
}

# Iterate the placement of edges until placement is created
set placement [place [array get edges] {}]

puts "Corners tile ID product: [get_corner_product $placement]"


# Remove border from tile
# tile - {row0 row1 row2 .. }
#        row<n> - string representation
# Returns tile with boarder removed
proc remove_border {tile} {
    for {set row 1} {$row < [expr [llength $tile] - 1]} {incr row} {
        set line [lindex $tile $row]
        lappend ret [string range $line 1 end-1]
    }

    return $ret
}

# Creates an array from a tile
# tile - {row0 row1 row2 .. }
#        row<n> - string representation
proc tile_to_array {tile} {
    set y 0
    foreach row $tile {
        set x 0
        foreach char [split $row ""] {
            set array_tile($x,$y) $char
            incr x
        }
        incr y
    }

    return [array get array_tile]
}

# Rotate tile clockwise
# tile - {row0 row1 row2 .. }
#        row<n> - string representation
proc rotate_tile {tile} {
    # Create an array representation of the tile
    array set array_tile [tile_to_array $tile]

    # Get the boundaries
    get_min_max [array get array_tile]

    # Handles rotation of the tile
    for {set y $miny} {$y <= $maxy} {incr y} {
        set row ""
        for {set x $minx} {$x <= $maxx} {incr x} {
            set row "${row}$array_tile($y,[expr $maxy-$x])"
        }
        lappend ret $row
    }

    return $ret
}

# Flip tile vertically
# tile - {row0 row1 row2 .. }
#        row<n> - string representation
proc flip_tile {tile} {
    for {set row [expr [llength $tile] -1]} {$row >= 0} {incr row -1} {
        lappend ret [lindex $tile $row]
    }
    return $ret
}

# Concat tiles to large image
# Placement is list of:
#  {x,y {tile_id {{top top_rev} {right right_rev} {bottom bottom_rev} {left left_rev}}} flip rotations}
proc concat_tiles {placement} {
    upvar 1 tiles tiles

    # Create an array represetnation of the placement
    array set array_placement $placement

    # Get boundaries of placement
    get_min_max $placement

    for {set y $miny} {$y <= $maxy} {incr y} {
        for {set x $minx} {$x <= $maxx} {incr x} {
            # Get information about tile id
            lassign $array_placement($x,$y) id edges flip rotations

            # Grab tile, flip and rotate it
            set tile [remove_border $tiles($id)]
            if {$flip == 1} {
                set tile [flip_tile $tile]
            }
            for {set i 0} {$i < $rotations} {incr i} {
                set tile [rotate_tile $tile]
            }

            # Place the tile in the image
            set dx 0
            set dy 0
            foreach row $tile {
                set dx 0
                foreach char [split $row ""] {
                    set image([expr $x * [llength $tile] + $dx],[expr $y * [llength $tile] + $dy]) $char
                    incr dx
            }
                incr dy
            }

        }
    }
    return [array get image]
}


# Creates a tile from an array
proc array_to_tile {a} {
    # Recreate array
    array set array_a $a

    # Get boundaries
    get_min_max $a

    for {set y $miny} {$y <= $maxy} {incr y} {
        set row ""
        for {set x $minx} {$x <= $maxx} {incr x} {
            set row "${row}$array_a($x,$y)"
        }
        lappend tile $row
    }

    return $tile
}

# Reads the creature file and create a list represenations for all '#' marked squares
# {x0 y0 x1 y1 x2 y2 .. }
# where x<n> y<n> is offset from upper left corner to a '#'
proc get_creature {} {
    # Read the creature file
    set fp [open "creature" r]
    set fd [read $fp]
    close $fp

    set y 0
    foreach row [split $fd "\n"] {
        set x 0
        if {$row != ""} {
            foreach char [split $row ""] {
                if {$char == "#"} {
                    lappend creature $x $y
                }
                incr x
            }
        }
        incr y
    }

    return $creature
}

# Finds all occurances of pattern in image
# Returns a list of coordinates where pattern was found
proc find_in_image {pattern image} {
    # Recreate image array
    array set array_image $image

    set coords []

    # Go through all points in image and check if pattern matches
    foreach {k v} [array get array_image] {
        lassign [split $k ","] x y

        set found 1
        foreach {dx dy} $pattern {
            set new_x [expr $x + $dx]
            set new_y [expr $y + $dy]
            if {![info exists array_image($new_x,$new_y)] || $array_image($new_x,$new_y) != "#"} {
                set found 0
                break
            }
        }
        if {$found == 1} {
            lappend coords [list $x $y]
        }
    }

    return $coords
}

set image [array_to_tile [concat_tiles $placement]]
set creature [get_creature]

# Try all orientations
foreach flips {0 1} {
    foreach rotates {0 1 2 3} {
        # Check if the creature is found
        set coords [find_in_image $creature [tile_to_array $image]]

        if {[llength $coords] != 0} {
            break
        }
        set image [rotate_tile $image]
    }
    if {[llength $coords] != 0} {
        break
    }
    set image [flip_tile $image]
}

# Create an array representation of the possibly flipped/rotated image
array set array_image [tile_to_array $image]

# Mark up the creatures
foreach coord $coords {
    lassign $coord x y

    foreach {dx dy} $creature {
        set new_x [expr $x + $dx]
        set new_y [expr $y + $dy]

        set array_image($new_x,$new_y) O
    }
}

# Count remaining '#'
set count 0
foreach {k v} [array get array_image] {
    if {$v == "#"} {
        incr count
    }
}

puts "Habitat's water roughness: $count"
