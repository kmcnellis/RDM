//
//  ViewController.swift
//  RDM-2
//
//  Created by гык-sse2 on 21/08/2018.
//  Copyright © 2018 гык-sse2. All rights reserved.
//

import Cocoa

@objc class SheetViewController: NSViewController, NSTextFieldDelegate {
    private var _resolution = Resolution()
    private var _aspectRatio: [UInt32] = [0, 0]

    private weak var _parent: ViewController!

    @IBOutlet weak var widthField      : NSTextField!
    @IBOutlet weak var heightField     : NSTextField!
    @IBOutlet weak var widthRatioField : NSTextField!
    @IBOutlet weak var heightRatioField: NSTextField!

    @objc var width: UInt32 {
        get {
            return _resolution.width
        }
        set {
            _resolution.width = newValue
        }
    }

    @objc var height: UInt32 {
        get {
            return _resolution.height
        }
        set {
            _resolution.height = newValue
        }
    }

    @objc var widthRatio: UInt32 {
        get {
            return _aspectRatio[0]
        }
        set {
            _aspectRatio[0] = newValue
            if height != 0 {
                width = height / heightRatio * newValue
            }
        }
    }

    @objc var heightRatio: UInt32 {
        get {
            return _aspectRatio[1]
        }
        set {
            _aspectRatio[1] = newValue
            if width != 0 {
                height = width / widthRatio * newValue
            }
        }
    }

    @IBAction func add(_ sender: Any?) {
        if _parent.arrayController.selectionIndexes.count == 0 {
            _parent.resolutions.append(_resolution)
        }
        _parent.arrayController.content = _parent.resolutions
        _parent.arrayController.rearrangeObjects()
        dismiss(self)
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        _parent = (presentingViewController as! ViewController)
        if _parent.arrayController.selectionIndexes.count == 1 {
            _resolution = _parent.arrayController.selectedObjects.first as! Resolution
        }

        widthField .integerValue = Int(width)
        heightField.integerValue = Int(height)

        _refreshRatio()
    }

    override func viewWillLayout() {
        super.viewWillLayout()
        preferredContentSize = view.frame.size
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        widthField      .delegate = self
        heightField     .delegate = self
        widthRatioField .delegate = self
        heightRatioField.delegate = self
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        _free()
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let id = (obj.object as? NSTextField)?.identifier?.rawValue else { return }

        switch id {
        case "width", "height":
            _refreshRatio()
        case "widthRatio":
            widthField .integerValue = Int(width)
        case "heightRatio":
            heightField.integerValue = Int(height)
        default:
            print("error")
        }
    }

    private func _refreshRatio() {
        _aspectRatio[0] = _resolution.width
        _aspectRatio[1] = _resolution.height
        _aspectRatio.simplify()

        widthRatioField .integerValue = Int(widthRatio)
        heightRatioField.integerValue = Int(heightRatio)
    }

    private func _free() {
        self._resolution  = Resolution()
        self._aspectRatio = [0, 0]
    }
}
