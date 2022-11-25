//
//  ThumbnailProvider.swift
//  PrintyThumbnail
//
//  Created by Luke Van In on 2022/11/24.
//

import UIKit
import QuickLookThumbnailing

import PrintySDK


final class ThumbnailProvider: QLThumbnailProvider {
    
    enum ThumbnailError: Error {
        case cannotOpenDocument
    }
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        // There are three ways to provide a thumbnail through a QLThumbnailReply. Only one of them should be used.
        
        Task {
            let document = await Document(fileURL: request.fileURL)
            let opened = await document.open()
            
            guard opened == true else {
                let error = ThumbnailError.cannotOpenDocument
                handler(nil, error)
                return
            }
            
            let image = await document.getImage()
            let elementSize = min(
                request.maximumSize.width / CGFloat(image.width),
                request.maximumSize.height / CGFloat(image.height)
            )
            let dotSize = elementSize * 0.8
            let configuration = ImageRenderer.Configuration(
                elementSize: CGSize(width: elementSize, height: elementSize),
                dotSize: CGSize(width: dotSize, height: dotSize),
                dotColor: .systemCyan,
                borderColor: nil,
                backgroundColor: .white
            )
            let renderer = ImageRenderer(configuration: configuration)
            let uiImage = renderer.renderImage(image)
            
            // First way: Draw the thumbnail into the current context, set up with UIKit's coordinate system.
            let reply = QLThumbnailReply(
                contextSize: request.maximumSize,
                currentContextDrawing: { () -> Bool in
                    // Draw the thumbnail here.
                    let bounds = CGRect(origin: .zero, size: request.maximumSize)
                    uiImage.draw(in: bounds)
                    
                    // Return true if the thumbnail was successfully drawn inside this block.
                    return true
                }
            )
            handler(reply, nil)
        }
        
        /*
        
        // Second way: Draw the thumbnail into a context passed to your block, set up with Core Graphics's coordinate system.
        handler(QLThumbnailReply(contextSize: request.maximumSize, drawing: { (context) -> Bool in
            // Draw the thumbnail here.
         
            // Return true if the thumbnail was successfully drawn inside this block.
            return true
        }), nil)
         
        // Third way: Set an image file URL.
        handler(QLThumbnailReply(imageFileURL: Bundle.main.url(forResource: "fileThumbnail", withExtension: "jpg")!), nil)
        
        */
    }
}
