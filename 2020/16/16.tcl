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

# Parse indata
# Create a list with ranges for the different fields (ranges)
# Create a list of field names (field_names)
# Create a list with my ticket values (my_ticket)
# Create a list containing lists of other ticket vlues (other_tickets)
set my     0
set nearby 0
foreach data $indata {
    if {[regexp {([a-z ]*): ([0-9-]*) or ([0-9-]*)} $data match field first second]} {
        lappend ranges [list $first $second]
        lappend field_names $field
        continue
    }

    if {$data == "your ticket:"} {
        set my 1
        set nearby 0
        continue
    }

    if {$data == "nearby tickets:"} {
        set my 0
        set nearby 1
        continue
    }


    if {$my == 1} {
        set my_ticket [split $data ","]
        continue
    }

    if {$nearby == 1} {
        lappend other_tickets [split $data ","]
    }
}

# Check a number vs range "x-y"
# Returns 1 if within x-y, otherwise 0
proc check_range {num range} {
    lassign [split $range "-"] min max

    if  {$num >= $min && $num <= $max} {
        return 1
    } else {
        return 0
    }
}

# Get the error rate for a single ticket
# For each number on the ticket, check all ranges
proc get_error_rate {ticket ranges} {
    set error_rate 0
    foreach num $ticket {
        set valid 0
        foreach rangepair $ranges {
            foreach range $rangepair {
                if {[check_range $num $range] == 1} {
                    set valid 1
                }
            }
        }
        if {$valid == 0} {
            incr error_rate $num
        }
    }
    return $error_rate
}

# Check the all the tickets and increment the error rate
# Also create a list with faulty ticket indexes which is needed for part 2
set ticket_no 0
set error_rate 0
foreach other $other_tickets {
    set er [get_error_rate $other $ranges]
    if {$er > 0} {
        incr error_rate $er
        lappend discard_indexes $ticket_no
    }
    incr ticket_no
}

puts "Error rate: $error_rate"

# Disard tickets containing invalid values
if {[info exist discard_indexes]} {
    set discard_indexes [lsort -dec -unique -integer $discard_indexes]
    foreach index $discard_indexes {
        set other_tickets [lreplace $other_tickets $index $index]
    }
}

# For each range pair check against all remaining tickets which fields that is a viable option
# Create a list where each item is a list of viable indexes on the ticket (possible)
for {set range_index 0} {$range_index < [llength $ranges]} {incr range_index} {
    set check_ranges [lindex $ranges $range_index]
    set ok_index {}
    for {set ticket_index 0} {$ticket_index < [llength $field_names]} {incr ticket_index} {

        foreach other $other_tickets {
            set check_value [lindex $other $ticket_index]

            set valid 0
            foreach range $check_ranges {
                if {[check_range $check_value $range] == 1} {
                    set valid 1
                }
            }

            if {$valid == 0} {
                break
            }
        }
        if {$valid == 0} {
            continue
        }

        lappend ok_index $ticket_index
    }

    lappend possible $ok_index
}

# Remove num from all lists within the list
proc remove {num possible} {
    foreach poss $possible {
        set search [lsearch $poss $num]
        if {$search != -1} {
            set poss [lreplace $poss $search $search]
        }
        lappend new_possible $poss
    }
    return $new_possible
}


# Map by checking if there is only one possible ticket index. Fixed mapping found.
# Remove that ticket index from all other possibilities
# Loop until all fields are mapped to an index
while {[array size map_field_to_index] != [llength $possible]} {
    for {set field_index 0} {$field_index < [llength $possible]} {incr field_index} {
        set ticket_indexes [lindex $possible $field_index]
        if {[llength $ticket_indexes] == 1} {
            set map_field_to_index($field_index) $ticket_indexes
            set possible [remove $ticket_indexes $possible]
        }

    }
}

# Get the "departure" fields
set departed [lsearch -all $field_names "departure*"]

# Remap the field to ticket_index and multiply the values
set product 1
foreach field_index $departed {
    set ticket_index $map_field_to_index($field_index)

    set product [expr $product * [lindex $my_ticket $ticket_index]]
}

puts "Product of all departure fields: $product"
