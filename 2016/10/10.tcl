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

proc receives {type bot_number chip} {
    global bot
    global output
    global inst
    set var "${type}($bot_number)"
    if {[info exists $var]} {
        set cur_value [expr $${var}]
        lappend cur_value $chip
        set ${type}($bot_number) $cur_value
        if {$type == "bot"} {
            if {[lindex $cur_value 0] == 61 && [lindex $cur_value 1] == 17} {
                puts "Bot $bot_number compares [lindex $cur_value 0] [lindex $cur_value 1]"
            }

            if {[llength $cur_value] == 2} {
                set cur_inst $inst($bot_number)
                set low_type    [lindex $cur_inst 0]
                set low_number  [lindex $cur_inst 1]
                set high_type   [lindex $cur_inst 2]
                set high_number [lindex $cur_inst 3]
                bot_gives $bot_number $low_type $low_number $high_type $high_number
                return 0
            } else {
                return 0
            }
        }
        return 0
    } else {
        set ${type}($bot_number) [list $chip]
        return 0
    }
}

proc bot_gives {bot_number low_type low_number high_type high_number} {
    global bot
    global output
    set bot_chips $bot($bot_number)
    set low_return [receives $low_type $low_number [expr min([join $bot_chips ","])]]
    set high_return [receives $high_type $high_number [expr max([join $bot_chips ","])]]
    set bot($bot_number) []
}

# Read instructions
foreach data $indata {
    if {[regexp {bot ([0-9]+) gives low to (bot|output) ([0-9]+) and high to (bot|output) ([0-9]+).*} $data _match bot_number low_type low_number high_type high_number]} {
        set inst($bot_number) [list $low_type $low_number $high_type $high_number]
    }
}

foreach data $indata {
    if {[regexp {value ([0-9]+) goes to bot ([0-9]+)} $data _match chip bot_number]} {
        receives bot $bot_number $chip
    }
}

puts "Multiplication: [expr $output(0) * $output(1) * $output(2)]"
