#!/usr/bin/tclsh

proc is_in_children {searchfor innode} {
    set search [lindex $searchfor 0]
    set children [lindex $innode 1]
    return [lsearch $children $search]
}

#proc insert_in_tree {insert tree} {
#    set search [lindex $searchfor 0]
#    set root [lindex $tree 0]
#    if {$search == $root} {
#	set children 

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

# Build the node list
foreach data $indata {
    set pair [split $data "->"]
    set root [split [lindex $pair 0]]
    set weight [string trim [lindex $root 1] "()"]
    set root [lindex $root 0]
    set children [split [lindex $pair 2] ","]
    set clean_children {}
    foreach child $children {
	lappend clean_children [string trimleft $child]
    }
    
    lappend node_list [list $root $clean_children $weight]
}

# Find the node which is not part of anyones children
for {set i 0} {$i < [llength $node_list]} {incr i} {
    set parent 0
    for {set j 0} {$j < [llength $node_list]} {incr j} {
	set index_in_children [is_in_children [lindex $node_list $i] [lindex $node_list $j]]
	if {$index_in_children != -1} {
	    set parent 1
	    break
	}
    }
    if {$parent == 0} {
	puts "Root node: [lindex $node_list $i]"
	break
    }
}
puts ""

# Proc for inserting nodes in a tree (lists of lists)
proc insert_in_tree {node parent} {
    global node_list

    set parent_children [lindex $parent 1]
    set node_children [lindex $node 1]

    set node [lreplace $node 1 1 {}]
    
    if {$node_children == {}} {
	return $node
    } else {
	set child_nodes {}
	foreach child $node_children {
	    lappend child_nodes [insert_in_tree [lindex $node_list [lsearch $node_list $child*]] $node]
	}
	set node [lreplace $node 1 1 $child_nodes]
	return $node
    }
}

# Insert nodes and start with the node found above being the root
set tree_root [insert_in_tree [lindex $node_list $i] {root {} 0}]

# Get weight of a tree
proc get_weight {tree} {
    set children [lindex $tree 1]
    if {$children == {}} {
	return [lindex $tree 2]
    }
    set sum 0
    foreach child $children {
	set child_weight [get_weight $child]
	set sum [expr $sum + $child_weight]
    }
    return [expr $sum + [lindex $tree 2]]
}

# Returns if all numbers in the list are equal
proc all_equal list {
    set unique [llength [lsort -unique $list]]
    if {$unique == 1} {
	return 1
    } else {
	return 0
    }
}    

# Find the max index of a list of numbers
proc find_list_max {list} {
    set max       0
    set max_index -1
    for {set i 0} {$i < [llength $list]} {incr i} {
	if {[lindex $list $i] > $max} {
	    set max       [lindex $list $i]
	    set max_index $i
	}
    }
    return $max_index
}

# Find and prints the too heavy node and what the weight should be
proc find_heavy_node {tree diff} {
    set weights {}
    while {1} {
	set children [lindex $tree 1]
	foreach child $children {
	    lappend weights [get_weight $child]
	}
	if {[all_equal $weights]} {
	    puts "Node [lindex $tree 0] with weigth [lindex $tree 2]"
	    puts "Node should have weight [expr [lindex $tree 2] - $diff]"
	    exit 0
	}
	set max_index [find_list_max $weights]
	set other_index [expr ($max_index + 1) % [llength $weights]]
	set max_weight [lindex $weights $max_index]
	set other_weight [lindex $weights $other_index]
	set diff [expr $max_weight - $other_weight]
	find_heavy_node [lindex $children $max_index] $diff
    }
}

find_heavy_node $tree_root 0
