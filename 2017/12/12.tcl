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

foreach data $indata {
    set pair [split $data " "]
    set who [lindex $pair 0]
    set com_paths [lrange $pair 2 end]
    set com_paths [lmap v $com_paths { string trim $v "," }]
    
    set dataarray($who) $com_paths
}

proc get_com_nodes {index} {
    global visited
    global dataarray
    if {[info exists visited($index)]} {
	return
    } else {
	set visited($index) 1
	foreach node $dataarray($index) {
	    get_com_nodes $node
	}
    }
}

get_com_nodes 0

puts "Size of group containing 0: [array size visited]"

set groups 1
for {set i 0} {$i < [array size dataarray]} {incr i} {
    if {[info exists visited($i)]} {
	continue
    } else {
	get_com_nodes $i
	incr groups
    }
}

puts "Number of groups: $groups"
	
	
