#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	set indata [lappend indata [regexp -inline -all -- {\S+} $row]]
    }
}

for {set i 0} {$i < 256} {incr i} {
    lappend clist $i
}

proc knot {clist pos len} {
    set length [llength $clist]
    set dual_list [concat $clist $clist]
    set rev_cand [lrange $dual_list $pos [expr $pos + $len - 1]]
    set rev_list [lreverse $rev_cand]

    set dual_list [concat [lrange $dual_list 0 [expr $pos - 1]] $rev_list [lrange $dual_list [expr $pos + $len] end]]

    return [concat [lrange $dual_list $length [expr $length + $pos - 1]] [lrange $dual_list $pos [expr $length - 1]]]
    
}

set skip 0
set current_pos 0

foreach length [split $indata ","] {
    set clist [knot $clist $current_pos $length]
    set current_pos [expr ($current_pos + $length + $skip) % [llength $clist]]
    incr skip
}

puts "Multiplication of first two: [expr [lindex $clist 0] * [lindex $clist 1]]"

set clist {}
for {set i 0} {$i < 256} {incr i} {
    lappend clist $i
}

foreach char [split $indata ""] {
    set lengths [lappend lengths [scan $char %c]]
}
set lengths [concat $lengths {17 31 73 47 23}]

set skip 0
set current_pos 0
for {set i 0} {$i < 64} {incr i} {
    foreach length $lengths {
	set clist [knot $clist $current_pos $length]
	set current_pos [expr ($current_pos + $length + $skip) % [llength $clist]]
	incr skip
    }
}

for {set i 0} {$i < 16} {incr i} {
    set xor [lindex $clist [expr $i * 16]]
    for {set j 1} {$j < 16} {incr j} {
	set xor [expr $xor ^ [lindex $clist [expr ($i * 16) + $j]]]
    }
    lappend dense $xor
}

puts -nonewline "Hash: "
foreach num $dense {
    puts -nonewline [format %02x $num]
}
puts ""
