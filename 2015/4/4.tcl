#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	#lappend indata [regexp -inline -all -- {\S+} $row]
	lappend indata $row
    }
}


package require md5

set i 1

while {1} {
    set md5sum [::md5::md5 -hex "$indata$i"]

    set fivefirst [string range $md5sum 0 4]
    set sixfirst  [string range $md5sum 0 5]

    if {![info exist fivezeroes] && [string equal $fivefirst "00000"]} {
        set fivezeroes $i
    }

    if {![info exist sixzeroes] && [string equal $sixfirst "000000"]} {
        set sixzeroes $i
    }

    if {[info exist fivezeroes] && [info exist sixzeroes]} {
        break
    }

    incr i
}


puts "Five leading zeroes: $fivezeroes"
puts "Six leading zeroes: $sixzeroes"
