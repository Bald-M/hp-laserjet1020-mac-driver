on run
	display dialog "Remove LaserJet 1020 Mac Kit, its driver files, and print queues still using this driver?" buttons {"Cancel", "Uninstall"} default button "Uninstall" cancel button "Cancel" with title "Uninstall LaserJet 1020 Mac Kit" with icon caution
	set toolPath to (POSIX path of (path to me)) & "Contents/Resources/Uninstall.command"
	set commandLine to (quoted form of toolPath) & " --yes"
	try
		set resultText to do shell script commandLine with administrator privileges
		display dialog resultText buttons {"OK"} default button "OK" with title "Uninstall complete"
	on error errorMessage number errorNumber
		if errorNumber is -128 then return
		display dialog ("Uninstall failed: " & errorMessage) buttons {"OK"} default button "OK" with title "LaserJet 1020 Mac Kit" with icon caution
	end try
end run
