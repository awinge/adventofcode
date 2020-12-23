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

# Double linked list insert
proc insert_after {value where} {
    upvar 1 linked linked
    upvar 1 length length

    if {![info exists linked]} {
        set linked($value) [list $value $value]
    } elseif {$length == 1} {
        set linked($where) [list $value $value]
        set linked($value) [list $where $where]
    } else {
        lassign $linked($where) last      next
        lassign $linked($next)  next_last next_next

        set linked($where) [list $last  $value]
        set linked($next)  [list $value $next_next]
        set linked($value) [list $where $next]
    }
    incr length
}

# Double linked list delete
# Will not work for small lists
proc delete {value} {
    upvar 1 linked linked
    upvar 1 length length

    lassign $linked($value) last next
    lassign $linked($last)  last_last last_next
    lassign $linked($next)  next_last next_next

    set linked($last) [list $last_last $next]
    set linked($next) [list $last $next_next]

    unset linked($value)
    incr length -1
}

# Get a list of the double linked list
proc get_list {start} {
    upvar 1 linked linked

    lappend ret $start
    set loop [lindex $linked($start) 1]
    while {$loop != $start} {
        lappend ret $loop
        set loop [lindex $linked($loop) 1]
    }
    return $ret
}

# Parse the indata
foreach data $indata {
    set last _
    foreach num [split $data ""] {
        if {![info exists current]} {
            set current $num
        }
        insert_after $num $last
        set last $num
    }
}

# Do a move
proc move {current} {
    upvar 1 linked linked
    upvar 1 length length

    # Pickup
    set pick [lindex $linked($current) 1]
    for {set i 0} {$i < 3} {incr i} {
        lappend picked $pick
        set pick [lindex $linked($pick) 1]
    }

    # Figure out the destination
    set destination [expr ($current - 1)]
    while {[lsearch $picked $destination] != -1 || $destination == 0} {
        set destination [expr ($length + 1 + $destination - 1) % ($length + 1)]
    }

    # Do the actual pickup
    foreach pick $picked {
        delete $pick
    }

    # Insert the pickups in reverse order
    foreach pick [lreverse $picked] {
        insert_after $pick $destination
    }

    # Return the new current
    return [lindex $linked($current) 1]
}

# Save these orignals for part 2
array set orig_linked [array get linked]
set orig_current $current
set orig_length $length

for {set i 0} {$i < 100} {incr i} {
    set current [move $current]
}
puts "Cup labels after 1: [join [lrange [get_list 1] 1 end] ""]"

# Get back to the orignal state
array unset linked
array set linked [array get orig_linked]
set length  $orig_length
set current $orig_current

# Insert all numbers up to a million
for {set i 1000000} {$i > 9} {incr i -1} {
    insert_after $i $last
}

# Do the 10 million moves
for {set i 0} {$i < 10000000} {incr i} {
    set current [move $current]
}

# Get the two items clockwise of 1
set next      [lindex $linked(1)     1]
set next_next [lindex $linked($next) 1]

puts "Multiply label $next with next next $next_nest: [expr $next * $next_next]"
