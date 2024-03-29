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

# Parse the input and create the scanner arrays
# Also add the first scanner found to the aligned list and
# the rest to an unalinged list
foreach data $indata {
    if {[regexp -- {--- scanner ([0-9]*) ---} $data match scan_no]} {

        # Set first scanner we find to aligned and the rest are unaligned
        if {![info exists aligned]} {
            lappend aligned scanner$scan_no
        } else {
            lappend unaligned scanner$scan_no
        }
        continue
    }

    if {[regexp {([0-9-]*),([0-9-]*),([0-9-]*)} $data match x y z]} {
        set scanner${scan_no}($x,$y,$z) 1
        continue
    }

    puts "Unparsed: $data"
    exit
}

# Proc for checking if delta dx dy dz is viable
# between scan_no1 and scan_no2
#
# Return 0 if a point from the first scan should
# appear on the second one and doesn't
# Returns 1 if 12 matching points are found
proc check {scan_no1_name scan_no2_name dx dy dz} {
    upvar 1 $scan_no1_name scan_no1
    upvar 1 $scan_no2_name scan_no2

    set count 0
    foreach {k1 v1} [array get scan_no1] {
        lassign [split $k1 ","] x1 y1 z1

        # Set nx,ny,nz according to the scan_no2
        set nx [expr $x1 + $dx]
        set ny [expr $y1 + $dy]
        set nz [expr $z1 + $dz]

        # Check if the beacon is within the scan_no2 range
        if {$nx >= -1000 && $nx <= 1000 &&
            $ny >= -1000 && $ny <= 1000 &&
            $nz >= -1000 && $nz <= 1000} {

            # Check that then is in scan_no2
            if ([info exist scan_no2($nx,$ny,$nz)]) {
                incr count
            } else {
                return 0
            }
        }

        if {$count >= 12} {
            return 1
        }
    }
    return 0
}

# Get if there is a viable delta between scan_no1 and scan_no2
# Deltas are generated by taking any pair of beacons
# one from scan_no1 and one from scan_no2
# If a viable detla is found return a list with a hit status
# and the viable delta.
#
# Since we need at least 12 beacons to match in the check function
# this can stop checking when there is less than 12 beacons left
# to generate deltas from. Then we should already found the delta.
proc get_delta {scan_no1_name scan_no2_name} {
    upvar 1 $scan_no1_name scan_no1
    upvar 1 $scan_no2_name scan_no2

    set size [array size scan_no1]
    set count 0
    foreach {k1 v1} [array get scan_no1] {
        incr count
        lassign [split $k1 ","] x1 y1 z1

        foreach {k2 v2} [array get scan_no2] {
            lassign [split $k2 ","] x2 y2 z2

            # Generate a delta
            set dx [expr $x2 - $x1]
            set dy [expr $y2 - $y1]
            set dz [expr $z2 - $z1]

            # Check if it is viable
            if {[check scan_no1 scan_no2 $dx $dy $dz]} {
                return [list 1 $dx $dy $dz]
            }
        }

        # Not enough beacons left
        if {$size - $count < 12} {
            return [list 0 0 0 0]
        }
    }

    return [list 0 0 0 0]
}

# Proc for checking overlap.
#
# It transforms the new_scan in all different ways and
# calls the get_delta function above to see if that transform
# is viable.
#
# If it is then align the beacon scan of new_scan with ref_scan.
# Also set the location of the new_scan in the global variable.

proc overlap {ref_scan_name new_scan_name} {
    upvar 1 $ref_scan_name ref_scan
    upvar 1 $new_scan_name new_scan

    global location

    # Pos/neg x, y and z axis
    set rx {1 -1  1 -1  1 -1  1 -1}
    set ry {1  1 -1 -1  1  1 -1 -1}
    set rz {1  1  1  1 -1 -1 -1 -1}

    # Which order to pick the x y and z from the scan
    set px {0 0 1 1 2 2}
    set py {1 2 0 2 0 1}
    set pz {2 1 2 0 1 0}

    # For every pick order
    for {set p 0} {$p < [llength $px]} {incr p} {

        # For every pos/neg x,y and z axis
        for {set r 0} {$r < [llength $rx]} {incr r} {
            array unset rscan

            # Transform each beacon accoding to r and p and create rscan
            foreach {k v} [array get new_scan] {
                set sc [split $k ","]

                set nx [expr [lindex $sc [lindex $px $p]] * [lindex $rx $r]]
                set ny [expr [lindex $sc [lindex $py $p]] * [lindex $ry $r]]
                set nz [expr [lindex $sc [lindex $pz $p]] * [lindex $rz $r]]

                set rscan($nx,$ny,$nz) 1
            }

            # Check if rscan is viable
            lassign [get_delta ref_scan rscan] hit dx dy dz
            if {$hit} {
                array unset new_scan

                # Align new_scan according to rscan and update values according
                # to the delta found
                foreach {rk rv} [array get rscan] {
                    lassign [split $rk ","] rx ry rz

                    set bx [expr $rx - $dx]
                    set by [expr $ry - $dy]
                    set bz [expr $rz - $dz]

                    set new_scan($bx,$by,$bz) 1
                }

                # Set the location of the scanner
                set location($new_scan_name) [list [expr -$dx] [expr -$dy] [expr -$dz]]
                return 1
            }
        }
    }
    return 0
}

# Set the location of scanner0
set location(scanner0) [list 0 0 0]

# Figure out all locations
while {[llength $unaligned]} {

    # Go though all unaligned
    for {set u 0} {$u < [llength $unaligned]} {incr u} {
        set u_scan [lindex $unaligned $u]

        set found 0

        # Try to match the unalinged with any that has been aligned already
        for {set a 0} {$a < [llength $aligned]} {incr a} {
            set a_scan [lindex $aligned $a]

            # If the combination has not been tested already and there is an overlap
            # Move the scanner to the aligned from unaligned
            # Since the unaligned and aligned lists are modified hop out of the loops
            # and start again
            if {![info exist tested($a_scan,$u_scan)] && [overlap $a_scan $u_scan]} {
                lappend aligned $u_scan
                set unaligned [lreplace $unaligned $u $u]
                set found 1
                break
            } else {
                set tested($a_scan,$u_scan) 1
            }
        }

        if {$found} {
            break
        }
    }
}

# For all scanners add its aligned beacons to the total array
set s 0
while {[info exist scanner$s]} {
    array set total [array get scanner$s]
    incr s
}

puts "Number of beacons: [array size total]"

# Go through all location pairwise and find the maximum manhattan distance
foreach {k1 v1} [array get location] {
    foreach {k2 v2} [array get location] {
        lassign $v1 x1 y1 z1
        lassign $v2 x2 y2 z2

        set manhattan [expr abs($x1-$x2) + abs($y1-$y2) + abs($z1-$z2)]

        if {![info exist max] || $manhattan > $max} {
            set max $manhattan
        }
    }
}

puts "Max manhattan distance: $max"
