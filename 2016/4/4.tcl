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

proc chartonum char {
    scan a "%c" base
    scan $char "%c" num
    return [expr $num - $base]
}

proc numtochar num {
    scan a "%c" base
    return [format %c [expr $num + $base]]
}

proc touple_compare {a b} {
    set diff [expr [lindex $a 1] - [lindex $b 1]]
    if {$diff} {
	return $diff
    } else {
	return [expr [chartonum [lindex $b 0]] - [chartonum [lindex $a 0]]]
    }
}

set sum 0
foreach data [split $fd "\n"] {
    set parts [split $data "-"]
    set name [lreplace $parts end end]
    set id_checksum [lindex $parts end]
    set id [lindex [split $id_checksum "\["] 0]
    set checksum [string trimleft $id_checksum "0123456789"]
    set checksum [string trim $checksum "\[\]"]
    
    array unset counter
    foreach word $name {
	foreach char [split $word ""] {
	    if {![info exist counter($char)]} {
		set counter($char) 1
	    } else {
		set counter($char) [expr $counter($char) + 1]
	    }
	}
    }
    
    set counter_list {}
    foreach {key value} [array get counter] {
	lappend counter_list [list $key $value]
    }
    set counter_list [lsort -decreasing -command touple_compare $counter_list]
    
    set calc_checksum [join [lmap touple [lrange $counter_list 0 4] {
	lindex $touple 0
    }] ""]


    if {$checksum == $calc_checksum} {
	set sum [expr $sum + $id]
	lappend checked_rooms [list $name $id]
    }
}

puts "The sum is: $sum"

# Decryption

foreach room $checked_rooms {
    set words [lindex $room 0]
    set id    [lindex $room 1]

    set room_name {}
    foreach word $words {
	set decrypted_word {}
	foreach char [split $word ""] {
	    set charnum [chartonum $char]
	    set charnum [expr ($charnum + $id) % 26]
	    lappend decrypted_word [numtochar $charnum]
	}
        lappend room_name [join $decrypted_word ""]
    }
    if {[lsearch $room_name northpole] != -1} {
	puts "Room $room_name with ID: $id"
    }
}

