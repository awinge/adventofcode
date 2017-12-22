#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	set indata [lappend indata $row]
    }
}

proc get_lit {i} {
    return [regexp -all {\#} $i]
}

proc get_center {i} {
    return [string index $i 4]
}

proc get_2border {i} {
    return "[string range $i 0 1][string reverse [string range $i 2 3]]"
}

proc get_border {i} {
    return "[string range $i 0 2][string index $i 5][string reverse [string range $i 6 8]][string index $i 3]"
}

proc hflip_image {i} {
    return "[string range $i 6 8][string range $i 3 5][string range $i 0 2]"
}

proc vflip_index {indexes} {
    foreach i $indexes {
        switch $i {
            0 {lappend ret 2}
            1 {lappend ret 1}
            2 {lappend ret 0}
            3 {lappend ret 7}
            4 {lappend ret 6}
            5 {lappend ret 5}
            6 {lappend ret 4}
            7 {lappend ret 3}
        }
    }
    return [lsort $ret]
}

proc hflip_index {indexes} {
    foreach i $indexes {
        switch $i {
            0 {lappend ret 6}
            1 {lappend ret 5}
            2 {lappend ret 4}
            3 {lappend ret 3}
            4 {lappend ret 2}
            5 {lappend ret 1}
            6 {lappend ret 0}
            7 {lappend ret 7}
        }
    }
    return [lsort $ret]
}

proc hflip_border {b} {
    return "[string reverse [string range $b 4 6]][string index $b 3][string reverse [string range $b 0 2]][string index $b 7]"
}

proc vflip_border {b} {
    return "[string reverse [string range $b 0 2]][string index $b 7][string reverse [string range $b 4 6]][string index $b 3]"
}

foreach data $indata {
    if {[regexp {([\.#/]+) => ([\.#/]+)} $data _match from to]} {
        set from [split $from /]
        set to [split $to /]
        set from_string [join $from ""]
        switch [llength $from] {
            2 { lappend from2to3 [list $from $to [get_2border $from_string]] }
            3 { lappend from3to4 [list $from $to [get_center $from_string] [get_border $from_string]] }
            default {
                puts "Do not know where to put: $from $to"
            }
        }
    } else {
        puts "Could not parse: $data"
    }
}

proc pattern2_match {image p_border} {
    set image     [join $image ""]
    set i_border  [split [get_2border $image] ""]
    set p_border  [split $p_border ""]
    set i_indexes [lsearch -all $i_border #]
    set p_indexes [lsearch -all $p_border #]

    if {[llength $i_indexes] != [llength $p_indexes]} {
        return 0
    }

    switch [llength $i_indexes] {
        0 -
        1 -
        3 -
        4 { return 1 }
    }

    for {set i 0} {$i < [llength $p_border]} {incr i} {
        if {$i_indexes == [lsort $p_indexes]} {
            return 1
        }
        set p_indexes [lmap v $p_indexes {
            expr ($v + 1) % [llength $p_border]
        }]
    }

    return 0
}

proc pattern3_match {image p_center p_border} {
    set image [join $image ""]
    set i_center [get_center $image]

    if {$i_center != $p_center} {
        return 0
    }

    set i_border [get_border $image]

    set i_border [split $i_border ""]
    set p_border [split $p_border ""]
    set i_indexes [lsearch -all $i_border #]
    set p_indexes [lsearch -all $p_border #]

    if {[llength $i_indexes] != [llength $p_indexes]} {
        return 0
    }

    switch [llength $i_indexes] {
        0 -
        1 -
        7 -
        8 { return 1 }
    }

    set p_vflip_indexes [vflip_index $p_indexes]
    set p_hflip_indexes [hflip_index $p_indexes]
    for {set i 0} {$i < 4} {incr i} {
        if {$i_indexes == [lsort $p_indexes]} {
            return 1
        }
        if {$i_indexes == [lsort $p_vflip_indexes]} {
            return 1
        }
        if {$i_indexes == [lsort $p_hflip_indexes]} {
            return 1
        }
        set p_indexes [lmap v $p_indexes {
            expr ($v + 2) % [llength $p_border]
        }]
        set p_vflip_indexes [hflip_index $p_indexes]
        set p_hflip_indexes [vflip_index $p_indexes]
    }
    return 0
}

proc vmerge {a b} {
    if {$a == {}} {
        return $b
    }
    for {set row 0} {$row < [llength $a]} {incr row} {
        lappend c "[lindex $a $row][lindex $b $row]"
    }
    return $c
}

proc hmerge {a b} {
    if {$a == {}} {
        return $b
    }
    return [concat $a $b]
}


proc enhance {image} {
    global from2to3
    global from3to4
    if {[expr [llength $image] % 2] == 0} {
        set row_merge {}
        for {set row 0} {$row < [expr [llength $image] / 2]} {incr row} {
            set column_merge {}
            for {set column 0} {$column < [expr [llength $image] / 2]} {incr column} {
                # pick out 2 rows
                set part [lrange $image [expr 2*$row] [expr (2*$row) + 1]]
                foreach r $part {
                    if {![info exists two_two]} {
                        set two_two [string range $r [expr 2*$column] [expr (2*$column) + 1]]
                    } else {
                        set two_two [concat $two_two [string range $r [expr 2*$column] [expr (2*$column) + 1]]]
                   }
                    
                }
                
                set found_match 0
                foreach p $from2to3 {
                    if {[pattern2_match $two_two [lindex $p 2]]} {
                        set column_merge [vmerge $column_merge [lindex $p 1]]
#                        if {$found_match == 1} {
#                            puts "dual match in 2x2"
#                            exit 1
#                        }
                        set found_match 1
                        break
                    }
                }
                if {$found_match == 0} {
                    puts "No match found in 2x2"
                    exit 1
                }
                unset two_two
            }
            set row_merge [hmerge $row_merge $column_merge]
        }
        return $row_merge
    } elseif {[expr [llength $image] % 3] == 0} {
        set row_merge {}
        for {set row 0} {$row < [expr [llength $image] / 3]} {incr row} {
            set column_merge {}
            for {set column 0} {$column < [expr [llength $image] / 3]} {incr column} {
                # pick out 3 rows
                set part [lrange $image [expr 3*$row] [expr (3*$row) + 2]]
                foreach r $part {
                    if {![info exists three_three]} {
                        set three_three [string range $r [expr 3*$column] [expr (3*$column) + 2]]
                    } else {
                        set three_three [concat $three_three [string range $r [expr 3*$column] [expr (3*$column) + 2]]]
                   }
                    
                }

                set found 0
                foreach p $from3to4 {
                    if {[pattern3_match $three_three [lindex $p 2] [lindex $p 3]]} {
                        set column_merge [vmerge $column_merge [lindex $p 1]]
#                        if {$found == 1} {
#                            puts "dual match in 3x3"
#                            exit 1
#                            rt#
#                        }
                        set found 1
                        break
                    }
                }
                if {$found == 0} {
                    puts "no match in 3x3"
                    exit 1
                }
                unset three_three
            }
            set row_merge [hmerge $row_merge $column_merge]
        }
        return $row_merge
    } else {
        puts "This is bad"
    }
}

set orig_image [list ".#." "..#" "###"]
set image $orig_image

set rounds 5
for {set i 0} {$i < $rounds} {incr i} {
    set image [enhance $image]
}

puts "Pixels on after 5 rounds: [llength [lsearch -all [split [join $image ""] ""] #]]"

set rounds 13
for {set i 0} {$i < $rounds} {incr i} {
    set image [enhance $image]
}

puts "Pizels on after 18 rounds: [llength [lsearch -all [split [join $image ""] ""] #]]"

