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

    if {[regexp {initial state: ([\#\.]*)} $data _match initstate]} {
        set pots     $initstate
        set leftmost 0
    }

    if {[regexp {([\#\.]*) => ([\#\.])} $data _match from to]} {
        set translations($from) $to
    }
}

proc extend {} {
    global pots
    global leftmost
    
    while {[string range $pots 0 4] != "....."} {
        incr leftmost -1
        set pots ".$pots"
    }
    while {[string range $pots end-4 end] != "....."} {
        set pots "${pots}."
    }
}

proc generation {} {
    global pots
    global leftmost
    global translations

    set newpots ".."
    for {set i 2} {$i < [expr [string length $pots] - 2]} {incr i} {
        set lookfor [string range $pots [expr $i - 2] [expr $i + 2]]
        if {[info exists translations($lookfor)]} {
            set newpots "${newpots}$translations($lookfor)"
        } else {
            set newpots "${newpots}."
        }
    }

    set pots "${newpots}.."
}

set orig_pots $pots
set orig_leftmost $leftmost

for {set i 0} {$i < 20} {incr i} {
    extend
    generation
}

set sum 0
set potvalue $leftmost
foreach char [split $pots ""] {
    if {$char == "#"} {
        set sum [expr $sum + $potvalue]
    }
    incr potvalue
}
puts "generation $i: The sum is: $sum"


set pots $orig_pots
set leftmost $orig_leftmost

set generation 0
for {set j 0} {$j < 5} {incr j} {
    for {set i 0} {$i < 1000} {incr i} {
        extend
        generation
        incr generation
    }
    
    set sum 0
    set potvalue $leftmost
    foreach char [split $pots ""] {
        if {$char == "#"} {
            set sum [expr $sum + $potvalue]
        }
        incr potvalue
    }
    puts "generation $generation: The sum is: $sum. Relation: [expr ${sum}.0 / $generation]"
}

puts "The sum of a generation is \"generation * 52 + 919\"."
puts "I.e. after genration 50000000000 the sum is: 2600000000919"

