#!/usr/bin/tclsh

set input "uugsqrei"
set testinput "flqrgnkx"


proc get_hash {input} {
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

    foreach char [split $input ""] {
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

    set result ""
    foreach num $dense {
        set result "${result}[format %08b $num]"
    }
    return $result
}

set grid ""
set used 0
for {set i 0} {$i < 128} {incr i} {
    set hash [get_hash "${input}-${i}"]
    set used [expr $used + [llength  [regexp -all -inline "1" $hash]]]
    set grid "${grid}${hash}"
}

puts "Used positions: $used"

set grid [split $grid ""]

set groups 0
set groupnum 2
proc mark_group {pos root} {
    global grid
    global groups
    global groupnum

    if {$pos < 0 || $pos >= [llength $grid]} {
	return
    }
    if {[lindex $grid $pos] != 1} {
	return
    }
    set leftpos  [expr $pos - 1]
    set rightpos [expr $pos + 1]
    set uppos    [expr $pos - 128]
    set downpos  [expr $pos + 128]

    set grid [lreplace $grid $pos $pos $groupnum]
    if {[expr $leftpos % 128] != 127} {
	mark_group $leftpos 0
    }
    if {[expr $rightpos % 128] != 0} {
	mark_group $rightpos 0
    }
    mark_group $uppos 0
    mark_group $downpos 0

    if {$root == 1} {
	set groups [expr $groups + 1]
	set groupnum [expr ($groupnum + 1) % 10]
	if {$groupnum == 0} {
	    set groupnum 2
	}
    }
}

proc print_grid {grid} {
    for {set j 0} {$j < 128} {incr j} {
	for {set i 0} {$i < 128} {incr i} {
	    set index [expr $j * 128 + $i]
	    puts -nonewline [lindex $grid $index]
	}
	puts ""
    }

}

#print_grid $grid 
for {set i 0} {$i < [llength $grid]} {incr i} {
    if {[lindex $grid $i] == 1} {
	mark_group $i 1
    }
}

#print_grid $grid 
puts "Number of groups: $groups"    
