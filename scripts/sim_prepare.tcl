set root [file normalize [file join [file dirname [info script]] ..]]
file mkdir mem
file mkdir results
file copy -force [file join $root mem sine_lut.hex] [file join [pwd] mem sine_lut.hex]
