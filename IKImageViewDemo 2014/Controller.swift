//
//  Controller.swift
//  IKImageViewDemo in Swift
//
//  Created by Armand Grillet, MIT license.
//

import Quartz
import Cocoa
import AppKit

class Controller: NSObject, NSWindowDelegate {
    /* Constants and variables. */
    @IBOutlet var window: NSWindow!
    @IBOutlet var imageView: IKImageView!
    
    var imageProperties: Dictionary<String,String> = [:]
    var imageUTType: String = ""
    var saveOptions: IKSaveOptions = IKSaveOptions()
    
    /* Override functions. */
    override func awakeFromNib () {
        /* Open the sample files that's inside the application bundle. */
        let path = Bundle.main.path(forResource: "earring", ofType: "jpg")
        let url = URL.init(fileURLWithPath: path!)
        
        self.openImageUrl(url)
        
        /* Customization of the IKImageView. */
        imageView.doubleClickOpensImageEditPanel = true
        imageView.currentToolMode = IKToolModeMove
        imageView.zoomImageToFit(self)
    }
    
    /* Event listeners. */
    func windowDidResize (_ notification: Notification) {
        imageView.zoomImageToFit(self)
    }
    
    /* IBActions. */
    @IBAction func doZoom (_ sender: AnyObject) {
        var zoom = Int()
        var zoomFactor = CGFloat()
        
        if sender.isKind(of: NSSegmentedControl) {
            zoom = sender.selectedSegment
        } else {
            zoom = sender.tag
        }
        
        switch zoom {
        case 0:
            imageView.zoomOut(self)
        case 1:
            imageView.zoomIn(self)
        case 2:
            imageView.zoomImageToActualSize(self)
        case 3:
            imageView.zoomImageToFit(self)
        default:
            break
        }
        
    }
    
    @IBAction func openImage (_ sender: AnyObject) {
        /* Present open panel. */
        let extensions = URL.init(string: "jpg/jpeg/JPG/JPEG/png/PNG/tiff/tif/TIFF/TIF")
        let types = extensions?.pathComponents
        
        /* Let the user choose an output file, then start the process of writing samples. */
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = types
        openPanel.canSelectHiddenExtension = true
        openPanel.beginSheetModal(for: window, completionHandler: {
                (result: NSInteger) -> Void in
                if result == NSFileHandlingPanelOKButton { // User did select an image.
                    self.openImageUrl(openPanel.url!)
                }
            }
        )

    }
    
    @IBAction func saveImage (_ sender: AnyObject) {
        let savePanel = NSSavePanel()
        
        saveOptions = IKSaveOptions(imageProperties: imageProperties as! [AnyHashable : Any], imageUTType: imageUTType)
        saveOptions.addAccessoryView(to: savePanel)
        
        var imageName = window.title
        savePanel.beginSheetModal(for: window,
            completionHandler: {
                (result: NSInteger) -> Void in
                if result == NSFileHandlingPanelOKButton {
                    self.savePanelDidEnd(savePanel, returnCode: result)
                }
            }
        )
    }
    
    @IBAction func switchToolMode (_ sender: AnyObject) {
        var newTool = Int()
        
        if sender.isKind(of: NSSegmentedControl) {
            newTool = sender.selectedSegment
        } else {
            newTool = sender.tag
        }
        
        switch (newTool) {
        case 0:
            imageView.currentToolMode = IKToolModeMove
        case 1:
            imageView.currentToolMode = IKToolModeSelect
        case 2:
            imageView.currentToolMode = IKToolModeCrop
        case 3:
            imageView.currentToolMode = IKToolModeRotate
        case 4:
            imageView.currentToolMode = IKToolModeAnnotate
        default:
            break
        }
    }
    
    /* Functions. */
    func openImageUrl (_ url: URL) {
        /* Use ImageIO to get the CGImage, image properties, and the image-UTType. */
        guard let isr = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }

        var options = NSDictionary(object: kCFBooleanTrue, forKey: kCGImageSourceShouldCache as! NSCopying)
        if let image = CGImageSourceCreateImageAtIndex(isr, 0, options) {
            if image.width > 0 && image.height > 0 {
//                imageProperties = CGImageSourceCopyPropertiesAtIndex(isr, 0, imageProperties)
                imageView.setImage(image, imageProperties: imageProperties)
                window.setTitleWithRepresentedFilename(url.lastPathComponent)
            }
        }
    }
    
    func savePanelDidEnd (_ sheet: NSSavePanel, returnCode: NSInteger) {
        if returnCode == NSOKButton {
            let newUTType: NSString = saveOptions.imageUTType as! NSString
            let image: CGImage = imageView.image().takeUnretainedValue()
            if image.width > 0 && image.height > 0 {
                let url = sheet.url as! CFURL
                let dest: CGImageDestination = CGImageDestinationCreateWithURL(url, newUTType, 1, nil)!
                CGImageDestinationAddImage(dest, image, saveOptions.imageProperties._bridgeToObjectiveC())
                CGImageDestinationFinalize(dest)
            } else {
                print("*** saveImageToPath - no image")
            }
        }
    }
}
