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

# Proc to write data to the memory according to the mask
proc write_data {addr data mask} {
    upvar 1 mem mem

    set bitnum 0
    set mask_data 0
    foreach mask_bit [lreverse [split $mask ""]] {
        set data_bit [expr $data % 2]

        switch $mask_bit {
            0 {
            }
            1 {
                incr mask_data [expr int(pow(2,$bitnum))]
            }
            X {
                if {$data_bit == 1} {
                    incr mask_data [expr int(pow(2,$bitnum))]
                }
            }
            default {
                puts "Unparsed mask"
                exit
            }
        }
        incr bitnum
        set data [expr $data / 2]
    }

    set mem($addr) $mask_data
}

foreach data $indata {
    if {[regexp {mask = ([0|1|X]*)} $data match new_mask]} {
        set mask $new_mask
        continue
    }

    if {[regexp {mem\[([0-9]*)\] = ([0-9]*)} $data match addr data]} {
        write_data $addr $data $mask
        continue
    }

    puts "Unparsed $data"
}

set sum 0
foreach {k v} [array get mem] {
    incr sum $v
}
puts "Sum of all memory values: $sum"


# Proc for expanding addr according to mask rules
# Returns a list of addresses
proc expand {addr mask} {
    set bitnum 0
    set mask_addr 0

    # Get the baseline address and a list of floating bits
    foreach mask_bit [lreverse [split $mask ""]] {
        set addr_bit [expr $addr % 2]

        switch $mask_bit {
            0 {
                if {$addr_bit == 1} {
                    incr mask_addr [expr int(pow(2,$bitnum))]
                }
            }
            1 {
                incr mask_addr [expr int(pow(2,$bitnum))]
            }
            X {
                lappend floating $bitnum
            }
            default {
                puts "Unparsed mask: $mask_bit"
                exit
            }
        }
        incr bitnum
        set addr [expr $addr / 2]
    }

    # Create the list of addresses based on the baseline address and
    # list of floating bits
    foreach bit $floating {
        set new_addr {}
        if {![info exists ret_addr]} {
            lappend ret_addr $mask_addr
            lappend ret_addr [expr $mask_addr + int(pow(2,$bit))]
        } else {
            foreach already_addr $ret_addr {
                lappend new_addr $already_addr
                lappend new_addr [expr $already_addr + int(pow(2,$bit))]
            }
            set ret_addr $new_addr
        }
    }

    return $ret_addr
}

# Reset memroy
array unset mem

foreach data $indata {
    if {[regexp {mask = ([0|1|X]*)} $data match new_mask]} {
        set mask $new_mask
        continue
    }

    if {[regexp {mem\[([0-9]*)\] = ([0-9]*)} $data match addr data]} {
        foreach exp_addr [expand $addr $mask] {
            set mem($exp_addr) $data
        }
        continue
    }

    puts "Unparsed $data"
}

set sum 0
foreach {k v} [array get mem] {
    incr sum $v
}
puts "Sum of all memory values: $sum"
