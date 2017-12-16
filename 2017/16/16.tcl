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

set orig_line [split "abcdefghijklmnop" ""]

proc swap {line a b} {
    set tmp [lindex $line $b]
    set line [lreplace $line $b $b [lindex $line $a]]
    set line [lreplace $line $a $a $tmp]
    return $line
}

proc do_dance {line indata} {
    foreach move [split $indata ","] {
        if {[regexp {x([0-9]+)/([0-9]+)} $move _match a b]} {
            set line [swap $line $a $b]
        }

        if {[regexp {p([a-p])/([a-p])} $move _match a b]} {
            set apos [lsearch $line $a]
            set bpos [lsearch $line $b]
            set line [swap $line $apos $bpos]
        }

        if {[regexp {s([0-9]+)} $move _match num]} {
            set line [concat [lrange $line end-[expr $num-1] end] [lrange $line 0 end-$num]]
        }
    }
    return $line
}

puts "After the dance: [join [do_dance $orig_line $indata] ""]"

set cyclic 0
set line $orig_line
while 1 {
    incr cyclic
    set line [do_dance $line $indata]
    if {$line == $orig_line} {
        break
    }
}

puts "Cyclic after $cyclic"

set line $orig_line
for {set i 0} {$i < [expr 1000000000 % $cyclic]} {incr i} {
    set line [do_dance $line $indata]
}

puts "After 1 Billion dance: [join $line ""]"
