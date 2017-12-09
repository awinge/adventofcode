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

# Check for abba sequences in data
proc contains_abba {data} {
#    puts [join $data ""]
    for {set i 0} {$i < [expr [llength $data] - 3]} {incr i} {
#	puts [lrange $data $i [expr $i + 3]]
	if {[lindex $data [expr $i + 0]] == [lindex $data [expr $i + 3]] &&
	    [lindex $data [expr $i + 1]] == [lindex $data [expr $i + 2]] &&
	    [lindex $data [expr $i + 0]] != [lindex $data [expr $i + 1]]} {
	    return 1
	}
    }
    return 0
}

proc get_abas {data} {
    set abas {}
    for {set i 0} {$i < [expr [llength $data] - 2]} {incr i} {
	if {[lindex $data [expr $i + 0]] == [lindex $data [expr $i + 2]] &&
	    [lindex $data [expr $i + 0]] != [lindex $data [expr $i + 1]]} {
	    lappend abas [join [lrange $data $i [expr $i + 2]] ""]
	}
    }
    return $abas
}

set supports_tls 0

foreach data $indata {
    set data_list [split $data ""]
#    puts $data_list
    set start_bracket_indexes [lsearch -all $data_list {\[}]
    set stop_bracket_indexes [lsearch -all $data_list {\]}]
    
#    puts $start_bracket_indexes
#    puts $stop_bracket_indexes

    set discard 0
    for {set i 0} {$i < [llength $start_bracket_indexes]} {incr i} {
	if {[contains_abba [lrange $data_list [lindex $start_bracket_indexes $i] [lindex $stop_bracket_indexes $i]]]} {
	    set discard 1
	    break
	}
    }
    if {$discard} {
#	puts "discard"
	continue
    }

    if {[contains_abba [lrange $data_list 0 [lindex $start_bracket_indexes 0]]]} {
	incr supports_tls
#	puts "support"
	continue
    }

    set support 0
    for {set i 1} {$i < [llength $start_bracket_indexes]} {incr i} {
	if {[contains_abba [lrange $data_list [lindex $stop_bracket_indexes [expr $i - 1]] [lindex $start_bracket_indexes $i]]]} {
	    set support 1
	    break
	}
    }
    if {$support} {
	incr supports_tls
#	puts "support"
	continue
    }
    
    if {[contains_abba [lrange $data_list [lindex $stop_bracket_indexes end] end]]} {
	incr supports_tls
#	puts "support"
	continue
    }
}

puts "Number that supports tls: $supports_tls"


set supports_ssl 0
    
foreach data $indata {
    set data_list [split $data ""]
#    puts $data_list
    set start_bracket_indexes [lsearch -all $data_list {\[}]
    set stop_bracket_indexes [lsearch -all $data_list {\]}]

    set all_abas {}
    set all_abas [concat $all_abas [get_abas [lrange $data_list 0 [lindex $start_bracket_indexes 0]]]]

    for {set i 1} {$i < [llength $start_bracket_indexes]} {incr i} {
	set all_abas [concat $all_abas [get_abas [lrange $data_list [lindex $stop_bracket_indexes [expr $i - 1]] [lindex $start_bracket_indexes $i]]]]
    }
    
    set all_abas [concat $all_abas [get_abas [lrange $data_list [lindex $stop_bracket_indexes end] end]]]

    set all_babs [lmap aba $all_abas {
	set aba_split [split $aba ""]
	set bab "[lindex $aba_split 1][lindex $aba_split 0][lindex $aba_split 1]"
    }]

#    puts $all_abas
#    puts $all_babs

    for {set i 0} {$i < [llength $start_bracket_indexes]} {incr i} {
	set support 0
	foreach bab $all_babs {
	    if {[string match "*$bab*" [join [lrange $data_list [lindex $start_bracket_indexes $i] [lindex $stop_bracket_indexes $i]] ""]]} {
		set support 1
		break
	    }
	}
	if {$support} {
	    incr supports_ssl
	    break
	}
    }
}

puts "Number that supports ssl: $supports_ssl"
