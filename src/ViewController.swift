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
    @IBOutlet var iconArrayController : NSArrayController!

    @IBOutlet weak var displayName : NSTextField!
    @objc          var vendorID    : UInt32         = 0
    @objc          var productID   : UInt32         = 0
    @objc dynamic  var resolutions : [Resolution] = []
    @objc dynamic  var icons       : Set<DisplayIcon> = []
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var xConstraint: NSLayoutConstraint!
    @IBOutlet weak var yConstraint: NSLayoutConstraint!
    @IBOutlet weak var resolutionPreviewImage: NSImageView!
    // For help
    var helpPopover     : NSPopover!
    
    @objc dynamic var selectedIcon : NSImage? {
        get {
            if iconArrayController.selectedObjects.count == 1 {
                return (iconArrayController.selectedObjects.first as? DisplayIcon)?.DisplayResolutionPreviewIcon
            }
            return nil
        }
        set (value) {
            if let image = value {
                let tmp = NSTemporaryDirectory() + UUID().uuidString
                try! image.tiffRepresentation?.write(to: URL(fileURLWithPath: tmp))
                
                let icon = icons.insert(DisplayIcon(properties: [
                    kDisplayResolutionPreviewIcon: tmp,
                    kResolutionPreviewX: 0,
                    kResolutionPreviewY: 0,
                    kResolutionPreviewWidth: 160,
                    kResolutionPreviewHeight: 90
                ])).memberAfterInsert
                iconArrayController.content = icons
                iconArrayController.setSelectedObjects([icon])
                iconArrayController.rearrangeObjects()
            }
            else {
                iconArrayController.setSelectedObjects([])
            }
        }
    }
    
    @objc var iconForBoardId : DisplayIcon? = nil
    @objc var displayProductName : String {
        get {
            return displayName.stringValue
        }
        set(value) {
            displayName.stringValue = value
        }
    }
    
    var sourceIconsPlists : [String] {
        get {
            return ["/System\(ViewController.rootdir)/Icons.plist"] + (ViewController.supportsLibraryDisplays ? ["\(ViewController.rootdir)/Icons.plist"] : [])
        }
    }
    
    var destinationIconsPlist : String {
        get {
            let dstPlist = "\(ViewController.rootdir)/Icons.plist"
            return ViewController.supportsLibraryDisplays ? dstPlist : "/System" + dstPlist
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

        if let a = plist[kScaleResolutionsKey] {
            if let b = a as? NSArray {
                resolutions.append(contentsOf: ((b as Array).map { Resolution(nsdata: $0 as? NSData) }))
            }
        }
        
        // Remove counterparts
        resolutions = resolutions.filter({ (res) -> Bool in
            return !(res.RawFlags == 0 && resolutions.contains(where: {$0.HiDPI && $0.height * 2 == res.height && $0.width * 2 == res.width}))
        })
        
        resolutions = Array(NSOrderedSet(array: resolutions)) as! [Resolution]
        
        var selection : [DisplayIcon] = []
        
        var computerBoardId : String? = nil
        if #available(OSX 10.13, *) {
            let p = Process()
            let pipe = Pipe()
                p.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
            p.arguments = ["-c", "IOPlatformExpertDevice", "-a"]
            p.standardOutput = pipe
            try! p.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            var format = PropertyListSerialization.PropertyListFormat.xml
            let dict = try! PropertyListSerialization.propertyList(from: data, options: [], format: &format) as! [String : AnyObject]
            if let children = dict["IORegistryEntryChildren"] as? [AnyObject] {
                if children.count == 1,
                   let item = children.first as? [String : AnyObject] {
                    if let data = item["board-id"] as? Data {
                       computerBoardId = String(data: data, encoding: String.Encoding.ascii)
                    }
                }
            }
        }
        
        for iconsPlist in sourceIconsPlists.map { NSMutableDictionary(contentsOf: URL(fileURLWithPath: $0)) ?? nil }.filter({$0 != nil}) {
            if let boards = iconsPlist!["board-ids"] as? [String : Any] {
                for board in boards {
                    if let boardDict = board.value as? [String : AnyHashable] {
                        if boardDict[kDisplayResolutionPreviewIcon] != nil {
                            let icon = icons.insert(DisplayIcon(properties: boardDict)).memberAfterInsert
                            if board.key == computerBoardId {
                                iconForBoardId = icon
                            }
                        }
                    }
                }
            }
            if let vendors = iconsPlist!["vendors"] as? [String : Any] {
                let defaultDisplayIcon = vendors[kDisplayIcon] as? String
                for vendor in vendors {
                    if let vendorDict = vendor.value as? [String : Any] {
                        let vendorDefaultDisplayIcon = vendorDict[kDisplayIcon] as? String ?? defaultDisplayIcon
                        if let products = vendorDict["products"] as? [String : Any] {
                            for product in products {
                                if var productDict = product.value as? [String : AnyHashable] {
                                    if vendorDefaultDisplayIcon != nil && !productDict.keys.contains(kDisplayIcon) {
                                        productDict[kDisplayIcon] = vendorDefaultDisplayIcon
                                    }
                                    if productDict[kDisplayResolutionPreviewIcon] != nil {
                                        let (_, displayIcon) = icons.insert(DisplayIcon(properties: productDict))
                                        if String(format: "%x", vendorID).lowercased() == vendor.key.lowercased() &&
                                            String(format:"%x", productID).lowercased() == product.key.lowercased() {
                                            selection = [displayIcon]
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        print(icons.count)
        

        // Initialize subviews
        calcController = (storyboard!.instantiateController(withIdentifier: "calculator") as! SheetViewController)

        helpPopover = NSPopover()
        helpPopover.contentViewController = (storyboard!.instantiateController(withIdentifier: "helpMessage") as! NSViewController)
        helpPopover.behavior = .semitransient

        // For better UI
        view.window!.standardWindowButton(.miniaturizeButton)!.isHidden = true
        view.window!.standardWindowButton(.zoomButton)!.isHidden = true
        view.window!.styleMask.insert(.resizable)

        self.iconArrayController.addObserver(self, forKeyPath: "selectedObjects", options: .new, context: nil)
        
        self.resolutionPreviewImage.imageScaling = NSImageScaling.scaleAxesIndependently
        self.resolutionPreviewImage.image = NSImage(contentsOfFile: "/System/Library/CoreServices/DefaultBackground.jpg")
        
        DispatchQueue.main.async {
            self.iconArrayController.sortDescriptors = [NSSortDescriptor(key: "ResolutionPreviewWidth", ascending: true)]            
            self.arrayController.content = self.resolutions
            self.iconArrayController.content = self.icons
            self.iconArrayController.setSelectedObjects(selection)            
        }
    }
    
    @IBAction func fitModel(_ sender: Any) {
        if let icon = iconForBoardId {
            iconArrayController.setSelectedObjects([icon])
        }
        else {
            iconArrayController.setSelectedObjects([])
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        switch keyPath {
        case "selectedObjects":
            willChangeValue(forKey: "selectedIcon")
            if iconArrayController.selectedObjects.count == 1,
               let icon = iconArrayController.selectedObjects.first as? DisplayIcon {
                icon.addObserver(self, forKeyPath: "ResolutionPreviewX", options: .new, context: nil)
                icon.addObserver(self, forKeyPath: "ResolutionPreviewY", options: .new, context: nil)
                icon.addObserver(self, forKeyPath: "ResolutionPreviewWidth", options: .new, context: nil)
                icon.addObserver(self, forKeyPath: "ResolutionPreviewHeight", options: .new, context: nil)
                self.xConstraint.constant = CGFloat(icon.ResolutionPreviewX)
                self.yConstraint.constant = CGFloat(-icon.ResolutionPreviewY)
                self.widthConstraint.constant = CGFloat(icon.ResolutionPreviewWidth)
                self.heightConstraint.constant = CGFloat(icon.ResolutionPreviewHeight)
            }
            else {
                self.xConstraint.constant = 0
                self.yConstraint.constant = 0
                self.widthConstraint.constant = 0
                self.heightConstraint.constant = 0                
            }
            self.view.needsLayout = true
            self.view.layout()
            didChangeValue(forKey: "selectedIcon")
            break
            
        case "ResolutionPreviewX", "ResolutionPreviewY", "ResolutionPreviewWidth", "ResolutionPreviewHeight":
            if iconArrayController.selectedObjects.count == 1,
               let icon = iconArrayController.selectedObjects.first as? DisplayIcon {
                self.xConstraint.constant = CGFloat(icon.ResolutionPreviewX)
                self.yConstraint.constant = CGFloat(-icon.ResolutionPreviewY)
                self.widthConstraint.constant = CGFloat(icon.ResolutionPreviewWidth)
                self.heightConstraint.constant = CGFloat(icon.ResolutionPreviewHeight)
            }
            else {
                self.xConstraint.constant = 0
                self.yConstraint.constant = 0
                self.widthConstraint.constant = 0
                self.heightConstraint.constant = 0                
            }
            break
            
        default:
            break
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.level = .floating // Always on top
    }

    @IBAction func add(_ sender: Any) {
        resolutions.append(Resolution())
        arrayController.content = resolutions
        arrayController.rearrangeObjects()
    }

    @IBAction func remove(_ sender: Any) {
        if arrayController.selectionIndexes.count > 0 {
            resolutions.remove(at: arrayController.selectionIndexes)
            arrayController.content = resolutions
            arrayController.rearrangeObjects()
        }
    }
    
    func saveIcon() {
        var saveScripts = [String]()
        var dict = (NSMutableDictionary(contentsOf: URL(fileURLWithPath: destinationIconsPlist)) as? [String : Any]) ?? [:]
        let productDict = iconArrayController.selectedObjects.count == 1 ? (iconArrayController.selectedObjects[0] as? DisplayIcon)?.Properties : nil
        let hexVendor = String(format: "%x", vendorID)
        let hexProduct = String(format: "%x", productID)
        
        var vendors = dict["vendors"] as? [String : Any] ?? [:]
        var vendorDict = vendors[hexVendor] as? [String : Any] ?? [:]
        var products = vendorDict["products"] as? [String : Any] ?? [:]
        if var pd = productDict {
            if let iconPath = pd[kDisplayResolutionPreviewIcon] as? String {
                if iconPath.hasPrefix(NSTemporaryDirectory()) {
                    pd[kDisplayResolutionPreviewIcon] = destinationFile + ".tiff"
                    saveScripts.append("mv '\(iconPath)' '\(destinationFile + ".tiff")'")
                }       
            }
            products[hexProduct] = pd
        }
        else {
            products.removeValue(forKey: hexProduct)
        }
        vendorDict["products"] = products
        vendors[hexVendor] = vendorDict
        dict["vendors"] = vendors
        
        let tmpFile = NSTemporaryDirectory() + UUID().uuidString
        NSDictionary(dictionary: dict).write(toFile: tmpFile, atomically: false)

        saveScripts.append("mv '\(tmpFile)' '\(destinationIconsPlist)'")
        if let error = NSAppleScript.executeAndReturnError(source: saveScripts.joined(separator: " && "),
                                                           asType: .shell,
                                                           withAdminPriv: true) {
            NSAlert(fromDict: error).beginSheetModal(for: view.window!)
        } else {
            view.window!.close()
        }
    }

    @IBAction func save(_ sender: Any) {
        if let error = RestoreSettingsItem.backupSettings(originalPlistPath: sourceFiles.last!) {
            NSAlert(fromDict: error).beginSheetModal(for: view.window!)
            return
        }

        let tmpFile = NSTemporaryDirectory() + UUID().uuidString

        plist[kDisplayProductName] = displayProductName as NSString
        
        let sortedResolutions = resolutions.sorted { (a, b) -> Bool in
            return a.width > b.width || a.width == b.width && a.height > b.height
        }
        
        let hiDPIResolutions = sortedResolutions.filter({($0).RawFlags & kFlagHiDPI != 0})
        let lowDPIResolutions = sortedResolutions.filter({($0).RawFlags & kFlagHiDPI == 0})
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

        let saveScripts = [
            "mkdir -p '\(destinationDir)'",
            "cp '\(tmpFile)' '\(destinationFile)'",
            "rm '\(tmpFile)'"
        ]

        if let error = NSAppleScript.executeAndReturnError(source: saveScripts.joined(separator: " && "),
                                                           asType: .shell,
                                                           withAdminPriv: true) {
            NSAlert(fromDict: error).beginSheetModal(for: view.window!)
        } else {
            saveIcon()
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
