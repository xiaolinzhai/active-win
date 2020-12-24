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

func printWindow(windowID:UInt32){
let windowImage: CGImage? =
    CGWindowListCreateImage(.null, .optionIncludingWindow, windowID,
                            [.boundsIgnoreFraming, .nominalResolution]);
    
    let targetSize = NSSize(width: 100.0, height: 100.0)
    let newImageResized =  windowImage!.asNSImage()!.resized(to: targetSize)!;
    print(newImageResized.base64String()!);
    //let uiImage = convertCIImageToUIImage(windowImage);
    //let imgRes = uiImage.scalePreservingAspectRatio(CGSize(100,100));
    
}

extension NSImage {
   
}


func resize(_ image: CGImage) -> CGImage? {
        var ratio: Float = 0.0
        let imageWidth = Float(image.width)
        let imageHeight = Float(image.height)
        let maxWidth: Float = 1024.0
        let maxHeight: Float = 768.0
        
        // Get ratio (landscape or portrait)
        if (imageWidth > imageHeight) {
            ratio = maxWidth / imageWidth
        } else {
            ratio = maxHeight / imageHeight
        }
        
        // Calculate new size based on the ratio
        if ratio > 1 {
            ratio = 1
        }
        
        let width = imageWidth * ratio
        let height = imageHeight * ratio
        
        guard let colorSpace = image.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: image.bitsPerComponent, bytesPerRow: image.bytesPerRow, space: colorSpace, bitmapInfo: image.alphaInfo.rawValue) else { return nil }
        
        // draw image to context (resizing it)
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: Int(width), height: Int(height)))
        
        // extract resulting image from context
        return context.makeImage()

    }



extension CGImage {
   /// Create a CIImage version of this image
   ///
   /// - Returns: Converted image, or nil
   func asCIImage() -> CIImage {
      return CIImage(cgImage: self)
   }

   /// Create an NSImage version of this image
   ///
   /// - Returns: Converted image, or nil
   func asNSImage() -> NSImage? {
      return NSImage(cgImage: self, size: .zero)
   }
}
extension NSImage {
   /// Create a CIImage using the best representation available
   ///
   /// - Returns: Converted image, or nil
   func asCIImage() -> CIImage? {
      if let cgImage = self.asCGImage() {
         return CIImage(cgImage: cgImage)
      }
      return nil
   }

   /// Create a CGImage using the best representation of the image available in the NSImage for the image size
   ///
   /// - Returns: Converted image, or nil
   func asCGImage() -> CGImage? {
      var rect = NSRect(origin: CGPoint(x: 0, y: 0), size: self.size)
      return self.cgImage(forProposedRect: &rect, context: NSGraphicsContext.current, hints: nil)
    }
    
    func resized(to newSize: NSSize) -> NSImage? {
            if let bitmapRep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
            ) {
                bitmapRep.size = newSize
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
                draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
                NSGraphicsContext.restoreGraphicsState()

                let resizedImage = NSImage(size: newSize)
                resizedImage.addRepresentation(bitmapRep)
                return resizedImage
            }

            return nil
        }
}

// CGImage转UIImage相对简单，直接使用UIImage的初始化方法即可
// 原理同上
//func convertCIImageToUIImage(cgImage:CGImage) -> UIImage {
//    let uiImage = UIImage.init(cgImage: cgImage)
//    // 注意！！！这里的uiImage的uiImage.ciImage 是nil
//    let ciImage = uiImage.ciImage
//    // 注意！！！上面的ciImage是nil，原因如下，官方解释
//    // returns underlying CIImage or nil if CGImageRef based
//    return uiImage
//}


//let imageData = NSData.alloc().initWithBase64EncodedString_options(base64String, NSDataBase64DecodingIgnoreUnknownCharacters);
//let image = NSImage.alloc().initWithData(imageData);


extension NSImage {

    func base64String() -> String? {
        guard
            let bits = self.representations.first as? NSBitmapImageRep,
            let data = bits.representation(using: .jpeg, properties: [NSBitmapImageRep.PropertyKey.compressionFactor:1.0])
        else {
            return nil
        }

        return "data:image/jpeg;base64,\(data.base64EncodedString())"
    }
}
