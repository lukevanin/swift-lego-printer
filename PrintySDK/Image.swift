//
//  Image.swift
//  Printy
//
//  Created by Luke Van In on 2022/11/24.
//

import Foundation


public struct Image: Equatable, Codable {
    
    public enum Element: Int, Codable {
        case x = 1
        case o = 0
    }
    
    public let width: Int
    public let height: Int
    public var pixels: [[Element]]
    
    public init(_ pixels: [[Element]]) {
        self.height = pixels.count
        self.width = pixels[0].count
        self.pixels = pixels
    }
    
    public init(width: Int, height: Int) {
        let row = Array<Element>(repeating: .o, count: width)
        self.pixels = Array<[Element]>(repeating: row, count: height)
        self.width = width
        self.height = height
    }
    
    public func transposed() -> Image {
        var output = Image(width: height, height: width)
        for y in 0 ..< height {
            for x in 0 ..< width {
                let pixel = getElement(x: x, y: y)
                output.setElement(x: y, y: x, value: pixel)
            }
        }
        return output
    }
    
    public func mirrored() -> Image {
        var output = Image(width: width, height: height)
        for y in 0 ..< height {
            for x in 0 ..< width {
                let pixel = getElement(x: x, y: y)
                output.setElement(x: width - x - 1, y: y, value: pixel)
            }
        }
        return output
    }

    public mutating func setElement(x: Int, y: Int, value: Element) {
        pixels[y][x] = value
    }

    public func getElement(x: Int, y: Int) -> Element {
        pixels[y][x]
    }
    
    public mutating func clear() {
        for y in 0 ..< height {
            for x in 0 ..< width {
                setElement(x: x, y: y, value: .o)
            }
        }
    }

    public static let checker13x13 = Image(
        [
            [.x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x],
            [.o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o],
            [.x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x],
            [.o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o],
            [.x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x],
            [.o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o],
            [.x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x],
            [.o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o],
            [.x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x],
            [.o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o],
            [.x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x],
            [.o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o],
            [.x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x],
        ]
    )
}
