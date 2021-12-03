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

# The length of the binary values
set length [string length [lindex $indata 0]]

# Returns positive value if the number of ones is most common
# Returns negative value if the number of zeros is most common
# Returns zero if the number of ones and zeros are the same
proc get_occur {data index} {
    set result 0
    foreach entry $data {
        if {[string index $entry $index]} {
            incr result +1
        } else {
            incr result -1
        }
    }
    return $result
}

# Calculate gamma and epsilon
set gamma 0
set epsilon 0
for {set index 0} {$index < $length} {incr index} {
    if {[get_occur $indata $index] > 0} {
        set gamma   [expr 2*$gamma   + 1]
        set epsilon [expr 2*$epsilon + 0]
    } else {
        set gamma   [expr 2*$gamma   + 0]
        set epsilon [expr 2*$epsilon + 1]
    }
}

puts "Power consumption: [expr $gamma * $epsilon]"

# Proc will return deducted data in respect to the index and
# if generation or scrubbing is wanted
proc deduct_data {data index gen} {

    # Figure out what to match according to specification
    set occur [get_occur $data $index]
    if {$gen} {
        if {$occur >= 0} {
            set match 1
        } else {
            set match 0
        }
    } else {
        if {$occur < 0} {
            set match 1
        } else {
            set match 0
        }
    }

    foreach entry $data {
        if {[string index $entry $index] == $match} {
            lappend new_data $entry
        }
    }

    return $new_data
}

# Calculate the scubbing
set data $indata
for {set index 0} {$index < $length} {incr index} {
    set data [deduct_data $data $index 1]

    if {[llength $data] == 1} {
        set gen [expr "0b$data"]
        break
    }
}

set data $indata
for {set index 0} {$index < $length} {incr index} {
    set data [deduct_data $data $index 0]

    if {[llength $data] == 1} {
        set scrub [expr "0b$data"]
        break
    }
}

puts "Life support rating: [expr $gen * $scrub]"
