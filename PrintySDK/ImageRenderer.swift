//
//  EditorImageRenderer.swift
//  Printy
//
//  Created by Luke Van In on 2022/11/24.
//

import UIKit


public struct ImageRenderer {
    
    public struct Configuration {
        
        public var elementSize: CGSize
        public var dotSize: CGSize
        public var dotColor: UIColor = .systemCyan
        public var borderColor: UIColor?
        public var backgroundColor: UIColor = .white

        public init(
            elementSize: CGSize,
            dotSize: CGSize,
            dotColor: UIColor = .systemCyan,
            borderColor: UIColor? = nil,
            backgroundColor: UIColor = .white
        ) {
            self.elementSize = elementSize
            self.dotSize = dotSize
            self.dotColor = dotColor
            self.borderColor = borderColor
            self.backgroundColor = backgroundColor
        }
    }
    
    public var configuration: Configuration
    
    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func renderImage(_ image: Image) -> UIImage {
        let size = CGSize(
            width: CGFloat(image.width) * configuration.elementSize.width,
            height: CGFloat(image.height) * configuration.elementSize.height
        )
        let bounds = CGRect(origin: .zero, size: size)
        let renderer = UIGraphicsImageRenderer(size: size)
        let inset = CGSize(
            width: (configuration.elementSize.width - configuration.dotSize.width) * 0.5,
            height: (configuration.elementSize.height - configuration.dotSize.height) * 0.5
        )
        let uiImage = renderer.image { context in
            // Fill background
            configuration.backgroundColor.setFill()
            context.fill(bounds)
            
            // Draw elements
            for y in 0 ..< image.height {
                for x in 0 ..< image.width {
                    let pixelBounds = CGRect(
                        x: CGFloat(x) * configuration.elementSize.width,
                        y: CGFloat(y) * configuration.elementSize.height,
                        width: configuration.elementSize.width,
                        height: configuration.elementSize.height
                    )
                    
                    if let borderColor = configuration.borderColor, configuration.elementSize.width > 4, configuration.elementSize.height > 4 {
                        let borderBounds = pixelBounds.insetBy(
                            dx: 1,
                            dy: 1
                        )
                        borderColor.setFill()
                        context.fill(pixelBounds)
                        configuration.backgroundColor.setFill()
                        context.fill(borderBounds)
                    }
                    
                    let pixel = image.getElement(x: x, y: y)
                    if pixel == .x {
                        let fillBounds = pixelBounds.insetBy(
                            dx: inset.width,
                            dy: inset.height
                        )
                        configuration.dotColor.setFill()
//                        context.fill(fillBounds)
                        context.cgContext.fillEllipse(in: fillBounds)
                    }
                }
            }
        }
        return uiImage
    }
}
