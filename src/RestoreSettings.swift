//
//  RestoreSettings.swift
//  RDM-2
//
//  Created by JNR on 31/08/2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Cocoa

@objc class RestoreSettingsItem : NSMenuItem {
    @objc var vendorID    : UInt32
    @objc var productID   : UInt32
    @objc var displayName : String
          var filePath    : String

    private static let backupDir = getAppSupportDir(withTrailingPath: "\(Bundle.main.bundleIdentifier!)/Backups")

    @objc init(title : String, action : Selector, vendorID : UInt32, productID : UInt32, displayName : String) {
        self.vendorID    = vendorID
        self.productID   = productID
        self.displayName = displayName
        self.filePath    = String(format: "\(ViewController.dirformat)/\(ViewController.fileformat)", self.vendorID, self.productID)

        super.init(title: title, action: action, keyEquivalent: "")
    }

    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func backupSettings(originalPlistPath : String) -> NSDictionary? {
        let plistSpecificPath = URL(fileURLWithPath: originalPlistPath).pathComponents.suffix(2)

        var backupScripts     = [String]()
        let currBackupDir     = RestoreSettingsItem.backupDir.appendingPathComponent(plistSpecificPath.first!).standardizedFileURL
        let backupPlistFile   = currBackupDir.appendingPathComponent(plistSpecificPath.last!).standardizedFileURL.path

        if FileManager.default.fileExists(atPath: backupPlistFile)
            || (!FileManager.default.fileExists(atPath: originalPlistPath)) {
            return nil
        }

        backupScripts.append("mkdir -p '\(currBackupDir.path)'")
        backupScripts.append("cp '\(originalPlistPath)' '\(backupPlistFile)'")

        return NSAppleScript.executeAndReturnError(source: backupScripts.joined(separator: " && "), asType: .shell)
    }

//    TODO: Maybe for uninstalling?
//    @objc static func restoreAllSettings() {
//        var restoreScripts = [String]()
//        let originalDir      = ViewController.rootdir.hasPrefix("/System") ? ViewController.rootdir : "/System" + ViewController.rootdir
//
//        for dir in (try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: backupDir), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? [] {
//            for file in (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? [] {
//                let specificPaths = file.pathComponents.suffix(2)
//                restoreScripts.append("mkdir -p '\(originalDir)/\(specificPaths.first!)'")
//                restoreScripts.append("mv -f '\(file.path)' '\(originalDir)/\(specificPaths.joined(separator: "/"))'")
//            }
//        }
//
//        if !restoreScripts.isEmpty {
//            if let errDict = execShellScript(restoreScripts.joined(separator: " && "), withAdminPriv: true) {
//                fatalError("Cannot restore original settings\n\(errDict.object(forKey: "NSAppleScriptErrorBriefMessage") as! String)")
//            }
//        }
//    }
//
//    TODO: porting whole application to swift
//    @objc func restoreSettingsGUI() {
//        let prompt = NSAlert()
//
//        prompt.window.level = .floating
//        prompt.alertStyle   = .warning
//        prompt.messageText  = "Restore all settings for \(displayName.trimmingCharacters(in: .whitespacesAndNewlines))?"
//
//        prompt.addButton(withTitle: "OK")
//        prompt.addButton(withTitle: "Cancel")
//
//        prompt.buttons[0].keyEquivalent = "\r"
//        prompt.buttons[1].keyEquivalent = "\u{1b}"
//
//        NSApp.activate(ignoringOtherApps: true)
//        if prompt.runModal() == .alertFirstButtonReturn {
//            var alert: NSAlert!
//
//            if let error = restoreSettings() {
//                alert = NSAlert(fromDict: error)
//            } else {
//                alert = NSAlert()
//                alert.window.level = .floating
//                alert.alertStyle   = .informational
//                alert.messageText  = "Restore success!"
//
//                alert.addButton(withTitle: "OK")
//                alert.buttons[0].keyEquivalent = "\r"
//            }
//
//            NSApp.activate(ignoringOtherApps: true)
//            alert.runModal()
//        }
//    }

    @objc func restoreSettings() -> NSDictionary? {
        var restoreScripts = [String]()

        let backupFilePath = RestoreSettingsItem.backupDir.appendingPathComponent(filePath).standardizedFileURL.path
        if !ViewController.supportsLibraryDisplays && ViewController.rootWriteable && FileManager.default.fileExists(atPath: backupFilePath) {
            restoreScripts.append("cp -f '\(backupFilePath)' '/System\(ViewController.rootdir)/\(filePath)'")            
        }
        
        if FileManager.default.fileExists(atPath: "\(ViewController.rootdir)/\(filePath)") {
            restoreScripts.append("rm -f '\(ViewController.rootdir)/\(filePath)'")
        }

        var error: NSDictionary? = nil
        if restoreScripts.count > 0 {
            error = NSAppleScript.executeAndReturnError(source: restoreScripts.joined(separator: " && "),
                                                        asType: .shell,
                                                        withAdminPriv: true)
        }
        return error
    }
}
