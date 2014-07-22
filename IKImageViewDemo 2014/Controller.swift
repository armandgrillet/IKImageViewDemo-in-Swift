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
    
    var imageProperties: NSDictionary = Dictionary<String, String>()
    var imageUTType: String = ""
    var saveOptions: IKSaveOptions = IKSaveOptions()
    
    /* Override functions. */
    override func awakeFromNib () {
        /* Open the sample files that's inside the application bundle. */
        var path = NSBundle.mainBundle().pathForResource("earring", ofType: "jpg")
        var url = NSURL.fileURLWithPath(path)
        
        self.openImageUrl(url)
        
        /* Customization of the IKImageView. */
        imageView.doubleClickOpensImageEditPanel = true
        imageView.currentToolMode = IKToolModeMove
        imageView.zoomImageToFit(self)
    }
    
    /* Event listeners. */
    func windowDidResize (notification: NSNotification?) {
        imageView.zoomImageToFit(self)
    }
    
    /* IBActions. */
    @IBAction func doZoom (sender: AnyObject) {
        var zoom = Int()
        var zoomFactor = CGFloat()
        
        if sender.isKindOfClass(NSSegmentedControl) {
            zoom = sender.selectedSegment
        } else {
            zoom = sender.tag()
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
    
    @IBAction func openImage (sender: AnyObject) {
        /* Present open panel. */
        let extensions = "jpg/jpeg/JPG/JPEG/png/PNG/tiff/tif/TIFF/TIF"
        let types = extensions.pathComponents
        
        /* Let the user choose an output file, then start the process of writing samples. */
        var openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = types
        openPanel.canSelectHiddenExtension = true
        openPanel.beginSheetModalForWindow(window,
            {
                (result: NSInteger) -> Void in
                if result == NSFileHandlingPanelOKButton { // User did select an image.
                    self.openImageUrl(openPanel.URL)
                }
            }
        )

    }
    
    @IBAction func saveImage (sender: AnyObject) {
        var savePanel = NSSavePanel()
        
        saveOptions = IKSaveOptions(imageProperties: imageProperties, imageUTType: imageUTType)
        saveOptions.addSaveOptionsAccessoryViewToSavePanel(savePanel)
        
        var imageName = window.title
        savePanel.beginSheetModalForWindow(window,
            {
                (result: NSInteger) -> Void in
                if result == NSFileHandlingPanelOKButton {
                    self.savePanelDidEnd(savePanel, returnCode: result)
                }
            }
        )
    }
    
    @IBAction func switchToolMode (sender: AnyObject) {
        var newTool = Int()
        
        if sender.isKindOfClass(NSSegmentedControl) {
            newTool = sender.selectedSegment
        } else {
            newTool = sender.tag()
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
    func openImageUrl (url: NSURL) {
        /* Use ImageIO to get the CGImage, image properties, and the image-UTType. */
        var isr = CGImageSourceCreateWithURL(url, nil).takeUnretainedValue()

        var options = NSDictionary(object: kCFBooleanTrue, forKey: kCGImageSourceShouldCache)
        var image = CGImageSourceCreateImageAtIndex(isr, 0, options).takeUnretainedValue()
        
        if CGImageGetWidth(image) > 0 && CGImageGetHeight(image) > 0 {
            imageProperties = CGImageSourceCopyPropertiesAtIndex(isr, 0.asUnsigned(), imageProperties).takeUnretainedValue()
            imageView.setImage(image, imageProperties: imageProperties)
            window.setTitleWithRepresentedFilename(url.lastPathComponent)
        }
    }
    
    func savePanelDidEnd (sheet: NSSavePanel, returnCode: NSInteger) {
        if returnCode == NSOKButton {
            var newUTType: NSString = saveOptions.imageUTType
            var image: CGImage = imageView.image().takeUnretainedValue()
            if CGImageGetWidth(image) > 0 && CGImageGetHeight(image) > 0 {
                var url = sheet.URL as CFURLRef
                var dest: CGImageDestination = CGImageDestinationCreateWithURL(url, newUTType, 1, nil).takeUnretainedValue()
                CGImageDestinationAddImage(dest, image, saveOptions.imageProperties.bridgeToObjectiveC())
                CGImageDestinationFinalize(dest)
            } else {
                println("*** saveImageToPath - no image")
            }
        }
    }
}
