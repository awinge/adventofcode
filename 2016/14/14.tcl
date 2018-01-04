#!/usr/bin/tclsh

package require md5

set input ahsbgdzn
set testinput abc

set stored_md5 {}
set last_index 0
proc get_md5 {input index keep md5extras} {
    global stored_md5
    global last_index
    if {$index > $last_index} {
        set md5sum [md5::md5 -hex "${input}${index}"]
        for {set i 0} {$i < $md5extras} {incr i} {
            set md5sum [md5::md5 -hex [string tolower $md5sum]]
        }
        if {$keep == 1} {
            set last_index $index
            lappend stored_md5 $md5sum
        }
        return $md5sum
    } else {
        set stored_index [expr [llength $stored_md5] - 1 - ($last_index - $index)]
        set md5sum [lindex $stored_md5 $stored_index]
        if {$keep == 0} {
            set stored_md5 [lreplace $stored_md5 $stored_index $stored_index]
        }
        return $md5sum
    }
}


set input $testinput

proc get_index_of_64th_key {input md5extras} {
    set found 0
    for {set i 1} {1} {incr i} {
        set md5sum [get_md5 $input $i 0 $md5extras]
        if {[regexp {([A-H0-9])\1\1} $md5sum _match char]} {
            for {set j [expr $i + 1]} {$j <= $i + 1000} {incr j} {
                set 2ndmd5sum [get_md5 $input $j 1 $md5extras]
                if {[regexp "$char$char$char$char$char" $2ndmd5sum]} {
                    incr found
                    break
                }
            }
        }
        if {$found == 64} {
            return $i
        }
    }
}

puts "Index [get_index_of_64th_key $testinput 0] for the 64th key."

set stored_md5 {}
set last_index 0

puts "Index [get_index_of_64th_key $testinput 2016] for the 64th key."
