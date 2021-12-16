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

# Create the binary representation of the hex digits
foreach data $indata {
    foreach nibble [split $data ""] {
        switch $nibble {
            0 { append bin "0000" }
            1 { append bin "0001" }
            2 { append bin "0010" }
            3 { append bin "0011" }
            4 { append bin "0100" }
            5 { append bin "0101" }
            6 { append bin "0110" }
            7 { append bin "0111" }
            8 { append bin "1000" }
            9 { append bin "1001" }
            A { append bin "1010" }
            B { append bin "1011" }
            C { append bin "1100" }
            D { append bin "1101" }
            E { append bin "1110" }
            F { append bin "1111" }
        }
    }
}

# Proc for getting a number of bits (length) from binary string
# Returns a list with bits and the remaining binary string
proc get_bits {bin length} {
    set bits [string range $bin 0 [expr $length - 1]]
    set bin [string replace $bin 0 [expr $length - 1]]

    return [list $bits $bin]
}

# Proc for getting a value in decimal form of length bits from binary string
# Returns a list with value and the remaining bin
proc get_value {bin length} {
    lassign [get_bits $bin $length] bits bin
    set value [expr 0b$bits]

    return [list $value $bin]
}

# Proc for pparsing the BITS transmission
proc parse {bin} {
    # Used for the version sum of all packets
    global version_sum

    # Version
    lassign [get_value $bin 3] version bin
    incr bits 3
    incr version_sum $version

    # Type
    lassign [get_value $bin 3] type bin
    incr bits 3

    # Check if it is a literal
    if {$type == 4} {
        set literal ""
        set more_bits 1
        while {$more_bits} {
            # First bit signals if more bits should be read
            lassign [get_value $bin 1] more_bits bin

            # Get the actual literal bits
            lassign [get_bits $bin 4] literal_bits bin
            append literal $literal_bits
            incr bits 5
        }
    } else {
        # Length type (bits or packet)
        lassign [get_value $bin 1] length_type bin
        incr bits 1

        switch $length_type {
            0 {
                # Bit length
                lassign [get_value $bin 15] length bin
                incr bits 15
                incr bits $length

                set bin [string range $bin 0 [expr $length - 1]]

                # Parse the subpackets as long as length allows
                # Put all values parsed in a list
                while {$length > 0} {
                    lassign [parse $bin] length_sub value
                    lappend values $value

                    set length [expr $length - $length_sub]
                    set bin [string replace $bin 0 [expr $length_sub - 1]]
                }
            }
            1 {
                # Number of packets
                lassign [get_value $bin 11] packets bin
                incr bits 11

                # Parse the subpackets
                # Put all values parsed in a list
                while {$packets > 0} {
                    lassign [parse $bin] length_sub value
                    lappend values $value

                    set bin [string replace $bin 0 [expr $length_sub - 1]]
                    incr packets -1
                    incr bits $length_sub
                }
            }
        }
    }

    # Do the operation on the list of values
    switch $type {
        0 { set value [expr [join $values +]] }
        1 { set value [expr [join $values *]] }
        2 { set value [expr min([join $values ,])] }
        3 { set value [expr max([join $values ,])] }
        4 { set value [expr 0b$literal] }
        5 {
            if {[lindex $values 0] > [lindex $values 1]} {
                set value 1
            } else {
                set value 0
            }
        }
        6 {
            if {[lindex $values 0] < [lindex $values 1]} {
                set value 1
            } else {
                set value 0
            }
        }
        7 {
            if {[lindex $values 0] == [lindex $values 1]} {
                set value 1
            } else {
                set value 0
            }
        }
    }

    return [list $bits $value]
}

lassign [parse $bin] _bits value

puts "Versions sum: $version_sum"
puts "Evaluated: $value"
