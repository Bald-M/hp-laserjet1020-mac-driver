on run
	set choice to button returned of (display dialog "管理 HP LaserJet 1020 打印机。卸载驱动时会打开终端并要求确认。" buttons {"取消", "添加打印机", "卸载驱动"} default button "添加打印机" cancel button "取消" with title "LaserJet 1020 Mac Kit")
	if choice is "添加打印机" then
		set toolPath to "/Library/Application Support/LaserJet1020MacKit/AddPrinter.command"
	else
		set toolPath to "/Library/Application Support/LaserJet1020MacKit/Uninstall.command"
	end if
	do shell script "/usr/bin/open " & quoted form of toolPath
end run
