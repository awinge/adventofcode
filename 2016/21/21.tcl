#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	lappend indata [regexp -inline -all -- {\S+} $row]
    }
}

proc do_instr {instr data} {
    if {[regexp {swap position ([0-9]) with position ([0-9])} $instr _match pos_a pos_b]} {
        set letter_a [string index $data $pos_a]
        set letter_b [string index $data $pos_b]
        set data [string replace $data $pos_a $pos_a $letter_b] 
        set data [string replace $data $pos_b $pos_b $letter_a] 
        return $data
    }

    if {[regexp {swap letter ([a-z]) with letter ([a-z])} $instr _match letter_a letter_b]} {
        set data [string map [list $letter_a $letter_b $letter_b $letter_a] $data]
        return $data
    }

    if {[regexp {rotate (left|right) ([0-9]*) step} $instr _match dir steps]} {
        switch $dir {
            left  { set data [string range $data $steps end][string range $data 0 [expr $steps - 1]] }
            right { set data [string range $data end-[expr $steps-1] end][string range $data 0 end-$steps] }
        }
        return $data
    }

    if {[regexp {rotate based on position of letter ([a-z])} $instr _match letter_a]} {
        set pos_a [string first $letter_a $data 0]
        set steps [expr $pos_a + 1]
        if {$pos_a >= 4} {
            incr steps
        }
        set steps [expr $steps % [string length $data]]
        set data [string range $data end-[expr $steps-1] end][string range $data 0 end-$steps]
        return $data
    }

    if {[regexp {revrotate letter ([a-z])} $instr _match letter_a]} {
        for {set i 0} {$i < [string length $data]} {incr i} {
            set testdata [string range $data $i end][string range $data 0 [expr $i - 1]]

            set pos_a [string first $letter_a $testdata 0]
            set steps [expr $pos_a + 1]
            if {$pos_a >= 4} {
                incr steps
            }
            set steps [expr $steps % [string length $testdata]]
            set comparedata [string range $testdata end-[expr $steps-1] end][string range $testdata 0 end-$steps]
            if {$data == $comparedata} {
                return $testdata
            }
        }
        puts "Did not find reverse action"
        exit
    }

    if {[regexp {reverse positions ([0-9]) through ([0-9])} $instr _match pos_a pos_b]} {
        set reversed [string reverse [string range $data $pos_a $pos_b]]
        set data [string replace $data $pos_a $pos_b $reversed]
        return $data
    }

    if {[regexp {move position ([0-9]) to position ([0-9])} $instr _match pos_a pos_b]} {
        set letter_a [string index $data $pos_a]
        set data [string replace $data $pos_a $pos_a]
        set data [string range $data 0 [expr $pos_b-1]]${letter_a}[string range $data $pos_b end]
        return $data
    }

    puts "Did not find parsing for: $instr"
    exit
}

set scrambling_input abcdefgh
set scrambled_input fbgdceah
set data $scrambling_input

foreach instr $indata {
    set data [do_instr $instr $data]
}

puts "Scrambling of $scrambling_input became $data"


proc rev_instr {instr} {
    if {[regexp {swap position ([0-9]) with position ([0-9])} $instr _match pos_a pos_b]} {
        return $instr
    }

    if {[regexp {swap letter ([a-z]) with letter ([a-z])} $instr _match letter_a letter_b]} {
        return $instr
    }

    if {[regexp {rotate (left|right) ([0-9]*) step} $instr _match dir steps]} {
        return [string map {left right right left} $instr]
    }

    if {[regexp {rotate based on position of letter ([a-z])} $instr _match letter_a]} {
        return "revrotate letter $letter_a"
    }

    if {[regexp {reverse positions ([0-9]) through ([0-9])} $instr _match pos_a pos_b]} {
        return $instr
    }

    if {[regexp {move position ([0-9]) to position ([0-9])} $instr _match pos_a pos_b]} {
        return "move position $pos_b to position $pos_a"
    }

    puts "Did not find parsing for: $instr"
    exit
}    

set data $scrambled_input

set indata [lreverse $indata]
foreach instr $indata {
    set instr [rev_instr $instr]
    set data [do_instr $instr $data]
}

puts "Descrambling of $scrambled_input became $data"


