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

set data [split [lindex $indata 0] " "]

# Used for recursive calculation
# proc returns a list of:
#  - Number of consumed list elements
#  - Metadata sum of the root node and children
#  - Value of the node root node
proc calculate {l} {
    set metasum 0
    set nodevalue 0

    lassign $l children metadata
    set consumed 2

    for {set c 0} {$c < $children} {incr c} {
        set child [lreplace $l 0 [expr $consumed - 1]]
        lassign [calculate $child] child_consumed child_metasum child_value
        lappend child_values $child_value
        set metasum [expr $metasum + $child_metasum]
        set consumed [expr $consumed + $child_consumed]
    }

    for {set m 0} {$m < $metadata} {incr m} {
        set metavalue [lindex $l $consumed]
        set metasum [expr $metasum + $metavalue]

        # Calculate the node value
        if {$children == 0} {
            set nodevalue $metasum
        } else {
            if {$metavalue != 0} {
                set metavalue [expr $metavalue - 1]
                if {$metavalue < [llength $child_values]} {
                    set nodevalue [expr $nodevalue + [lindex $child_values $metavalue]]
                }
            }
        }
        incr consumed
    }
    return [list $consumed $metasum $nodevalue]
}

lassign [calculate $data] consumed metasum nodevalue

puts "Metadata sum: $metasum"
puts "Value of root node: $nodevalue"
