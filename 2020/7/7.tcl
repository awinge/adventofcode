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

foreach data $indata {
    if {[regexp {(.*) bags contain (.*)\.} $data match bag contents]} {
        foreach c [split $contents ","] {
            set c [string trimleft $c " "]

            if {$c == "no other bags"} {
                continue
            }

            if {[regexp {([0-9]*) (.*) bag(s|)} $c match num insidebag]} {
                lappend rev_rules($insidebag) $bag
                lappend fwd_rules($bag) [list $num $insidebag]
            }
        }
    }
}

proc get_rev_bags {bag} {
    upvar 1 rev_rules rev_rules
    upvar 1 counted counted

    set total 0
    if {[info exists rev_rules($bag)] && ![info exist counted($bag)]} {
        foreach b $rev_rules($bag) {
            if {![info exist counted($b)]} {
                set total [expr $total + 1 + [get_rev_bags $b]]
                set counted($b) 1
            }
        }
    }
    return $total
}

proc get_fwd_bags {bag} {
    upvar 1 fwd_rules fwd_rules

    set total 1
    if {[info exists fwd_rules($bag)]} {
        foreach b $fwd_rules($bag) {
            lassign $b num insidebag

            set total [expr $total + ($num * [get_fwd_bags $insidebag])]
        }
    }
    return $total
}

set mybag "shiny gold"

puts "Bags that can contain $mybag bag: [get_rev_bags $mybag]"

# Not counting my own bag
set required_bags [expr [get_fwd_bags $mybag] - 1]

puts "Required bags for carrying $mybag bag: $required_bags"
