import AppKit

func getActiveBrowserTabURLAppleScriptCommand(_ appName: String) -> String? {
	switch appName {
	case "Google Chrome", "Brave Browser", "Microsoft Edge":
		return "tell app \"\(appName)\" to get the URL of active tab of front window"
	case "Safari":
		return "tell app \"Safari\" to get URL of front document"
	default:
		return nil
	}
}

// Show accessibility permission prompt if needed. Required to get the complete window title.
if !AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary) {
	print("active-win requires the accessibility permission in “System Preferences › Security & Privacy › Privacy › Accessibility”.")
	exit(1)
}

let frontmostAppPID = NSWorkspace.shared.frontmostApplication!.processIdentifier

// Show screen recording permission prompt if needed. Required to get the complete window title.
if !hasScreenRecordingPermission() {
	print("active-win requires the screen recording permission in “System Preferences › Security & Privacy › Privacy › Screen Recording”.")
	exit(1)
}

var c = 0;
if(CommandLine.arguments.count > 1){
	let com = CommandLine.arguments[1]
	if(com == "getAllWindow"){
        //getAllWindow()
        printWindow(windowID:722);
	}

}

/*  for arg in CommandLine.arguments {
 print(try! toJson(CommandLine.arguments))
    print("argument \(c) is: \(arg)")
    c += 1
}  */
/* getAllWindow() */
/*
print("[null")


print("]") */
exit(0)
