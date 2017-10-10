//
//  SQLiteStringValueFormatter.swift
//  Lift
//
//  Created by Carl Wieland on 10/10/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//



import Cocoa

protocol DestinationViewDelegate {
  func processURLs(_ urls: [URL], center: NSPoint)
}

class DestinationView: NSView {
  
  enum Appearance {
    static let lineWidth: CGFloat = 10.0
  }
  
  var delegate: DestinationViewDelegate?
  
  override func awakeFromNib() {
    setup()
  }

  func setup() {
    registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL,NSPasteboard.PasteboardType.filePromise])
  }
  
  override func draw(_ dirtyRect: NSRect) {
    
    if isReceivingDrag {
      NSColor.selectedControlColor.set()
      
      let path = NSBezierPath(rect:bounds)
      path.lineWidth = Appearance.lineWidth
      path.stroke()
    }
  }
  

  override func hitTest(_ aPoint: NSPoint) -> NSView? {
    return nil
  }
  
  func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
    
    var canAccept = false

    let pasteBoard = draggingInfo.draggingPasteboard()
    

    if pasteBoard.canReadObject(forClasses: [NSURL.self], options:nil) {
      canAccept = true
    }

    return canAccept
    
  }

  var isReceivingDrag = false {
    didSet {
      needsDisplay = true
    }
  }
  
  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    let allow = shouldAllowDrag(sender)
    isReceivingDrag = allow
    return allow ? .copy : NSDragOperation()
  }
  
  override func draggingExited(_ sender: NSDraggingInfo?) {
    isReceivingDrag = false
  }
  
  override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let allow = shouldAllowDrag(sender)
    return allow
  }
  
  
  override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
    
    //1.
    isReceivingDrag = false
    let pasteBoard = draggingInfo.draggingPasteboard()
    
    //2.
    let point = convert(draggingInfo.draggingLocation(), from: nil)
    //3.
    if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options:nil) as? [URL], urls.count > 0 {
      delegate?.processURLs(urls, center: point)
      return true
    }

    return false
    
  }
}
