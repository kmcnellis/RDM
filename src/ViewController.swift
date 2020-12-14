//
//  ViewController.swift
//  RDM-2
//
//  Created by гык-sse2 on 21/08/2018.
//  Copyright © 2018 гык-sse2. All rights reserved.
//

import Cocoa

let kScaleResolutionsKey = "scale-resolutions"
let kTargetDefaultPixelsPerMillimeterKey = "target-default-ppmm"

@objc class ViewController: NSViewController {

    // Actually /Library/Displays was introduced in one of Catalina updates, but I don't know which one
    static let supportsLibraryDisplays = ProcessInfo().isOperatingSystemAtLeast(
        OperatingSystemVersion(majorVersion: 10, minorVersion: 15, patchVersion: 0)) 
    static let rootWriteable = !supportsLibraryDisplays && !isSIPActive()
    static let rootdir       = "/Library/Displays/Contents/Resources/Overrides"
    static let dirformat     = "DisplayVendorID-%x"
    static let fileformat    = "DisplayProductID-%x"

    @IBOutlet var arrayController : NSArrayController!
              var calcController  : SheetViewController!
              var plist           : NSMutableDictionary!

    @IBOutlet weak var displayName : NSTextField!
    @objc          var vendorID    : UInt32         = 0
    @objc          var productID   : UInt32         = 0
    @objc dynamic  var resolutions : [Resolution] = []

    // For help
    var helpPopover     : NSPopover!

    @objc var displayProductName : String {
        get {
            return displayName.stringValue
        }
        set(value) {
            displayName.stringValue = value
        }
    }

    var sourceDirs : [String] {
        get {
            let srcDir = String(format: "\(ViewController.rootdir)/\(ViewController.dirformat)", vendorID)
            return ViewController.supportsLibraryDisplays ? [srcDir, "/System" + srcDir] : ["/System" + srcDir]
        }
    }
    
    var destinationDir : String {
        get {
            let dstDir = String(format: "\(ViewController.rootdir)/\(ViewController.dirformat)", vendorID)
            return ViewController.supportsLibraryDisplays ? dstDir : "/System" + dstDir
        }
    }

    var sourceFiles : [String] {
        get {
            return sourceDirs.map { String(format:"\($0)/\(ViewController.fileformat)", productID) }
        }
    }
    
    var destinationFile : String {
        get {
            return String(format:"\(destinationDir)/\(ViewController.fileformat)", productID)
        }
    }

    // For closing when esc key is pressed
    override func cancelOperation(_ sender: Any?) {
        self.view.window!.close()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        let plists = sourceFiles.map { NSMutableDictionary(contentsOf: URL(fileURLWithPath: $0)) ?? nil }.filter({$0 != nil})
        if !plists.isEmpty {
            plist = plists.first!!
            if let a = plist[kDisplayProductName] as? String {
                displayProductName = a
            }
        }
        else {
            plist = NSMutableDictionary()
        }

        resolutions = []
        if let a = plist[kScaleResolutionsKey] {
            if let b = a as? NSArray {
                resolutions = (b as Array).map { Resolution(nsdata: $0 as? NSData) }
            }
        }

        // Initialize subviews
        calcController = (storyboard!.instantiateController(withIdentifier: "calculator") as! SheetViewController)

        helpPopover = NSPopover()
        helpPopover.contentViewController = (storyboard!.instantiateController(withIdentifier: "helpMessage") as! NSViewController)
        helpPopover.behavior = .semitransient

        // For better UI
        view.window!.standardWindowButton(.miniaturizeButton)!.isHidden = true
        view.window!.standardWindowButton(.zoomButton)!.isHidden = true
        view.window!.styleMask.insert(.resizable)

        DispatchQueue.main.async {
            self.arrayController.content = self.resolutions
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.level = .floating // Always on top
    }

    @IBAction func add(_ sender: Any) {
        resolutions.append(Resolution())
        arrayController.rearrangeObjects()
    }

//    @IBOutlet weak var removeButton: NSButton!

    @IBAction func remove(_ sender: Any) {
        if arrayController.selectionIndexes.count > 0 {
            resolutions.remove(at: arrayController.selectionIndexes)
            arrayController.rearrangeObjects()
        }
    }

    @IBAction func save(_ sender: Any) {
        var saveScripts = [String]()

        if let error = RestoreSettingsItem.backupSettings(originalPlistPath: sourceFiles.last!) {
            NSAlert(fromDict: error).beginSheetModal(for: view.window!)
            return
        }

        let tmpFile = NSTemporaryDirectory() + UUID().uuidString

        plist[kDisplayProductName] = displayProductName as NSString
        
        resolutions = resolutions.sorted { (a, b) -> Bool in
            return a.width > b.width || a.width == b.width && a.height > b.height
        }
        
        let hiDPIResolutions = resolutions.filter({($0).RawFlags & kFlagHiDPI != 0})
        let lowDPIResolutions = resolutions.filter({($0).RawFlags & kFlagHiDPI == 0})
        let hiDPICounterparts = hiDPIResolutions.map { (r) -> Resolution in
            let res = Resolution()
            res.width = r.width * 2
            res.height = r.height * 2
            res.RawFlags = 0
            return res
        }        
        
        let finalResolutions = lowDPIResolutions + hiDPICounterparts + hiDPIResolutions
        
        plist[kScaleResolutionsKey] = finalResolutions.map { ($0 ).toData() } as NSArray
        if plist[kTargetDefaultPixelsPerMillimeterKey] == nil {
            plist[kTargetDefaultPixelsPerMillimeterKey] = 10.01
        }
        plist.write(toFile: tmpFile, atomically: false)

        saveScripts.append("mkdir -p '\(destinationDir)'")
        saveScripts.append("cp '\(tmpFile)' '\(destinationFile)'")
        saveScripts.append("rm '\(tmpFile)'")

        if let error = NSAppleScript.executeAndReturnError(source: saveScripts.joined(separator: " && "),
                                                           asType: .shell,
                                                           withAdminPriv: true) {
            NSAlert(fromDict: error).beginSheetModal(for: view.window!)
        } else {
            view.window!.close()
        }
    }

    @IBAction func calcAspectRatio(_ sender: Any) {
        presentAsSheet(calcController)
    }

    @IBAction func displayHelpmessage(_ sender: Any) {
        guard let sender = sender as? NSButton else { return }

        if helpPopover.isShown {
            helpPopover.close()
        } else {
            helpPopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
