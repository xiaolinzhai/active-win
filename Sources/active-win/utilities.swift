import AppKit


@discardableResult
func runAppleScript(source: String) -> String? {
	NSAppleScript(source: source)?.executeAndReturnError(nil).stringValue
}


func toJson<T>(_ data: T) throws -> String {
	let json = try JSONSerialization.data(withJSONObject: data)
	return String(data: json, encoding: .utf8)!
}


// Show the system prompt if there's no permission.
func hasScreenRecordingPermission() -> Bool {
	CGDisplayStream(
		dispatchQueueDisplay: CGMainDisplayID(),
		outputWidth: 1,
		outputHeight: 1,
		pixelFormat: Int32(kCVPixelFormatType_32BGRA),
		properties: nil,
		queue: DispatchQueue.global(),
		handler: { _, _, _, _ in }
	) != nil
}

func getAllWindow()  {
	let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
	print("[null")
	for window in windows {
    	print(",")
    	let windowOwnerPID = window[kCGWindowOwnerPID as String] as! Int

    	if windowOwnerPID != frontmostAppPID {
    		//continue
    	}

    	// Skip transparent windows, like with Chrome.
    	if (window[kCGWindowAlpha as String] as! Double) == 0 {
    		//continue
    	}

    	let bounds = CGRect(dictionaryRepresentation: window[kCGWindowBounds as String] as! CFDictionary)!

    	// Skip tiny windows, like the Chrome link hover statusbar.
    	let minWinSize: CGFloat = 50
    	if bounds.width < minWinSize || bounds.height < minWinSize {
    		//continue
    	}

    	let appPid = window[kCGWindowOwnerPID as String] as! pid_t

    	// This can't fail as we're only dealing with apps.
    	let app = NSRunningApplication(processIdentifier: appPid)

    	let appName = window[kCGWindowOwnerName as String] as! String

    	var dict: [String: Any] = [
    		"title": window[kCGWindowName as String] as? String ?? "",
    		"id": window[kCGWindowNumber as String] as! Int,
    		"bounds": [
    			"x": bounds.origin.x,
    			"y": bounds.origin.y,
    			"width": bounds.width,
    			"height": bounds.height
    		],
    		"owner": [
    			"name": appName,
    			"processId": appPid,
    			"bundleId": app?.bundleIdentifier!  ?? "",
    			"path": app?.bundleURL!.path  ?? ""
    		],
    		"memoryUsage": window[kCGWindowMemoryUsage as String] as! Int
    	]

    	// Only run the AppleScript if active window is a compatible browser.
    	if
    		let script = getActiveBrowserTabURLAppleScriptCommand(appName),
    		let url = runAppleScript(source: script)
    	{
    		dict["url"] = url
    	}

    	print(try! toJson(dict))

    	//exit(0)
    }
    print("]")
}
