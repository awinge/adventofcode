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

# Parse the indata
foreach data $indata {
    if {[regexp {(on|off) x=([0-9-]*)\.\.([0-9-]*),y=([0-9-]*)\.\.([0-9-]*),z=([0-9-]*)\.\.([0-9-]*)} $data match on x1 x2 y1 y2 z1 z2]} {

        if {$on == on} {
            set on 1
        } else {
            set on 0
        }

        # Limit to scope
        set x1 [expr max(-50, $x1)]
        set x2 [expr min(50, $x2)]
        set y1 [expr max(-50, $y1)]
        set y2 [expr min(50, $y2)]
        set z1 [expr max(-50, $z1)]
        set z2 [expr min(50, $z2)]

        # Loop over all dimensions
        for {set x $x1} {$x <= $x2} {incr x} {
            for {set y $y1} {$y <= $y2} {incr y} {
                for {set z $z1} {$z <= $z2} {incr z} {
                    set cubes($x,$y,$z) $on
                }
            }
        }
        continue
    }

    puts "Unparsed data: $data"
}

set on 0
foreach {k v} [array get cubes] {
    if {$v == 1} {
        incr on
    }
}
puts "Cubes on: $on"

# Proc for impacting cuboid a with cuboid b
#
# Remove the part of b that is intersecting with a
# Return a list of cubeoids representing what is left
# of a.
proc impact {a b} {
    lassign $a ax1 ax2 ay1 ay2 az1 az2 aon
    lassign $b bx1 bx2 by1 by2 bz1 bz2 bon

    # Not affecting each other at all, return complete a
    if {($ax1 > $bx2 || $ax2 < $bx1) ||
        ($ay1 > $by2 || $ay2 < $by1) ||
        ($az1 > $bz2 || $az2 < $bz1)} {
        return [list $a]
    }

    # b totally overlaps a, return empty list
    if {$bx1 <= $ax1 && $bx2 >= $ax2 &&
        $by1 <= $ay1 && $by2 >= $ay2 &&
        $bz1 <= $az1 && $bz2 >= $az2} {
        return [list]
    }

    # This is the intersection cuboid, i.e. what part of
    # cuboid a to remove
    set ix1 [expr max($ax1, $bx1)]
    set ix2 [expr min($ax2, $bx2)]
    set iy1 [expr max($ay1, $by1)]
    set iy2 [expr min($ay2, $by2)]
    set iz1 [expr max($az1, $bz1)]
    set iz2 [expr min($az2, $bz2)]


    # Split up a in regards to intersection

    # Add right part
    if {$ix2 < $ax2} {
        lappend ret [list [expr $ix2 + 1] $ax2 $ay1 $ay2 $az1 $az2 $aon]
    }

    # Add left part
    if {$ix1 > $ax1} {
        lappend ret [list $ax1 [expr $ix1 - 1] $ay1 $ay2 $az1 $az2 $aon]
    }

    # Add upper part
    if {$iy2 < $ay2} {
        lappend ret [list [expr max($ax1,$ix1)] [expr min($ax2,$ix2)] [expr $iy2 + 1] $ay2 $az1 $az2 $aon]
    }

    # Add lower part
    if {$iy1 > $ay1} {
        lappend ret [list [expr max($ax1,$ix1)] [expr min($ax2,$ix2)] $ay1 [expr $iy1 - 1] $az1 $az2 $aon]
    }

    # Add back part
    if {$iz2 < $az2} {
        lappend ret [list [expr max($ax1,$ix1)] [expr min($ax2,$ix2)] [expr max($ay1,$iy1)] [expr min($ay2,$iy2)] [expr $iz2 + 1] $az2 $aon]
    }

    # Add front part
    if {$iz1 > $az1} {
        lappend ret [list [expr max($ax1,$ix1)] [expr min($ax2,$ix2)] [expr max($ay1,$iy1)] [expr min($ay2,$iy2)] $az1 [expr $iz1 - 1] $aon]
    }

    return $ret
}


# parse the indata once more
set cuboids []
foreach data $indata {
    incr count
    if {[regexp {(on|off) x=([0-9-]*)\.\.([0-9-]*),y=([0-9-]*)\.\.([0-9-]*),z=([0-9-]*)\.\.([0-9-]*)} $data match on x1 x2 y1 y2 z1 z2]} {

        if {$on == "on"} {
            set on 1
        } else {
            set on 0
        }

        # The new cuboid to considered
        set new [list $x1 $x2 $y1 $y2 $z1 $z2 $on]

        set new_cuboids {}

        # Foreach existing cubeoid, impact it with the new one and add
        # what comes out to the list of cuboids
        foreach cuboid $cuboids {
            set new_cuboids [list {*}$new_cuboids {*}[impact $cuboid $new]]
        }

        # All also the new cuboid
        lappend new_cuboids $new

        set cuboids $new_cuboids
    }
}

set on 0
foreach cuboid $cuboids {
    lassign $cuboid x1 x2 y1 y2 z1 z2 on

    if {$on} {
        incr ons [expr ($x2 - $x1 + 1) * ($y2 - $y1 + 1) * ($z2 - $z1 + 1)]
    }
}

puts "Cubes on: $ons"
