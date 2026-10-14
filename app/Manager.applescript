on run
	display dialog "Connect and turn on the HP LaserJet 1020, then continue to printer setup." buttons {"Cancel", "Add Printer"} default button "Add Printer" cancel button "Cancel" with title "HP LaserJet 1020 Mac Driver"
	set toolPath to "/Library/Application Support/LaserJet1020MacKit/AddPrinter.command"
	do shell script "/usr/bin/open " & quoted form of toolPath
end run
