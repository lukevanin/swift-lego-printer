//
//  Document.swift
//  Printy
//
//  Created by Luke Van In on 2022/11/24.
//

import UIKit
import OSLog
import UniformTypeIdentifiers


private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Document")


public final class Document: UIDocument {
    
    public static let uti = UTType("com.lukevanin.printy.document")!
    
    public enum DocumentError: Error {
        case contentNotSupported
    }
    
    private struct FileFormat: Codable {
        let image: Image
    }
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private var image: Image = Image(width: 13, height: 13)
    
    public func clear() {
        modify { image in
            image.clear()
        }
    }
    
    public func getImage() -> Image {
        return image
    }
    
    public func setElement(x: Int, y: Int, value: Image.Element) {
        modify { image in
            image.setElement(x: x, y: y, value: value)
        }
    }
    
    private func modify(edit: (inout Image) -> Void) {
        let oldImage = image
        var newImage = oldImage
        edit(&newImage)
        guard newImage != oldImage else {
            return
        }
        image = newImage
        updateChangeCount(.done)
    }
    
    public override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else {
            throw DocumentError.contentNotSupported
        }
        logger.debug("Loading document: \(String(data: data, encoding: .utf8) ?? "<Invalid JSON>")")
        let file = try decoder.decode(FileFormat.self, from: data)
        self.image = file.image
    }
    
    public override func contents(forType typeName: String) throws -> Any {
        let file = FileFormat(image: image)
        let data = try encoder.encode(file)
        logger.debug("Saving document: \(String(data: data, encoding: .utf8) ?? "<Invalid JSON>")")
        return data
    }
    
    
}
