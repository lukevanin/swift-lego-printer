import Foundation
import OSLog

import SwiftMindstorms


private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Printer")


@MainActor final class Printer {
    
    // MARK: Configuration
    
    struct Configuration {
        struct Axis {
            var port: MotorPort
            var speed: Int
            var camLength: Measurement<UnitLength>
            var startAngle: Measurement<UnitAngle>
            var endAngle: Measurement<UnitAngle>
            var backlashAngle: Measurement<UnitAngle>
        }
        
        var xAxis: Axis
        var yAxis: Axis
        var penAxis: Axis
    }
    
    struct Image {
        
        enum Pixel {
            case x
            case o
        }
        
        let width: Int
        let height: Int
        var pixels: [[Pixel]]
        
        init(_ pixels: [[Pixel]]) {
            self.height = pixels.count
            self.width = pixels[0].count
            self.pixels = pixels
        }
        
        init(width: Int, height: Int) {
            let row = Array<Pixel>(repeating: .o, count: width)
            self.pixels = Array<[Pixel]>(repeating: row, count: height)
            self.width = width
            self.height = height
        }
        
        func transposed() -> Image {
            var output = Image(width: height, height: width)
            for y in 0 ..< height {
                for x in 0 ..< width {
                    let pixel = getPixel(x: x, y: y)
                    output.setPixel(x: y, y: x, value: pixel)
                }
            }
            return output
        }
        
        func mirrored() -> Image {
            var output = Image(width: width, height: height)
            for y in 0 ..< height {
                for x in 0 ..< width {
                    let pixel = getPixel(x: x, y: y)
                    output.setPixel(x: width - x - 1, y: y, value: pixel)
                }
            }
            return output
        }

        mutating func setPixel(x: Int, y: Int, value: Pixel) {
            pixels[y][x] = value
        }
    
        func getPixel(x: Int, y: Int) -> Pixel {
            pixels[y][x]
        }
        
        mutating func clear() {
            for y in 0 ..< height {
                for x in 0 ..< width {
                    setPixel(x: x, y: y, value: .o)
                }
            }
        }

        static let test = Image(
            [
                [.x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x],
                [.o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o],
                [.x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x, .o, .x],
                [.o, .x, .o, .x, .o, . x, .o, .x, .o, .x, .o, .x, .o],
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

//        static let test = Image(
//            [
//                [.x, .o, .o, .o, .o, .o, .o, .o, .o, .x],
//                [.x, .x, .x, .x, .x, .x, .x, .x, .x, .x],
//                [.x, .o, .o, .o, .o, .o, .o, .o, .o, .x],
//                [.x, .o, .x, .o, .o, .o, .o, .x, .o, .x],
//                [.x, .o, .o, .o, .o, .o, .o, .o, .o, .x],
//                [.x, .o, .o, .o, .x, .x, .o, .o, .o, .x],
//                [.x, .o, .o, .x, .o, .o, .x, .o, .o, .x],
//                [.x, .o, .o, .o, .o, .o, .o, .o, .o, .x],
//                [.o, .x, .x, .x, .x, .x, .x, .x, .x, .o],
//            ]
//        )
    }
    
    // MARK: State
    
//    private class AnyState {
//        unowned var context: Printer!
//
//        func enter() { }
//    }
    
    // MARK: Variables
    
    private var printing = false
    
    private let robot: Robot
    private let configuration: Configuration
    
    // MARK: Methods
    
    init(configuration: Configuration) async {
        let connection = await BluetoothConnection()
        let hub = await Hub(connection: connection)
        let robot = await Robot(orientation: .left, hub: hub)
        self.robot = robot
        self.configuration = configuration
    }
    
    func connect() {
        Task {
            await self.robot.connect()
        }
    }
    
    func reconnect() {
        Task {
            await self.robot.reconnect()
        }
    }
    
    func home() {
        Task {
            do {
                try await homeAxis(configuration.xAxis)
                try await homeAxis(configuration.yAxis)
                try await homeAxis(configuration.penAxis)
            }
            catch {
                logger.error("Cannot home printer \(error.localizedDescription)")
            }
        }
    }
    
    func test() {
        let image = Image.test
        print(image)
    }
    
    func stop() {
        printing = false
    }

    func print(_ image: Image) {
        Task {
            guard printing == false else {
                return
            }
            printing = true
            do {
//                try await plotImage(image.transposed().mirrored())
                try await plotImage(image)
            }
            catch {
                logger.error("Cannot print image \(error.localizedDescription)")
            }
            printing = false
        }
    }

    private func plotImage(_ image: Image) async throws {
        let count = image.pixels.count
        guard printing == true else {
            return
        }
        try await homeAxis(configuration.penAxis)
        guard printing == true else {
            return
        }
        try await homeAxis(configuration.yAxis)
        for y in 0 ..< count {
            guard printing == true else {
                return
            }
            try await stepAxis(configuration.yAxis, step: y, steps: count)
            let row = image.pixels[y]
            guard printing == true else {
                return
            }
            if row.contains(.x) == true {
                try await plotRow(row)
            }
        }
    }
    
    private func plotRow(_ row: [Image.Pixel]) async throws {
        guard printing == true else {
            return
        }
        let count = row.count
        try await homeAxis(configuration.xAxis)
        for x in 0 ..< count {
            guard printing == true else {
                return
            }
            try await stepAxis(configuration.xAxis, step: x, steps: count)
            guard printing == true else {
                return
            }
            if row[x] == .x {
                try await plotDot()
            }
        }
    }
    
    private func plotDot() async throws {
        let axis = configuration.penAxis
        try await robot.motorGoDirectionToPosition(
            port: axis.port,
            position: Int(axis.endAngle.converted(to: .degrees).value.rounded()),
            direction: .shortest,
            speed: axis.speed,
            stall: true,
            stop: 0
        )
        try await robot.motorGoDirectionToPosition(
            port: axis.port,
            position: Int(axis.startAngle.converted(to: .degrees).value.rounded()),
            direction: .shortest,
            speed: axis.speed,
            stall: true,
            stop: 0
        )
    }

    private func homeAxis(_ axis: Configuration.Axis) async throws {
        try await robot.motorGoDirectionToPosition(
            port: axis.port,
            position: Int(axis.startAngle.converted(to: .degrees).value.rounded()),
            direction: .shortest,
            speed: axis.speed,
            stall: true,
            stop: 0
        )
//        try await robot.motorGoDirectionToPosition(
//            port: axis.port,
//            position: Int((axis.startAngle + axis.backlashAngle).converted(to: .degrees).value.rounded()),
//            direction: .shortest,
//            speed: axis.speed,
//            stall: true,
//            stop: 0
//        )
    }
    
    private func stepAxis(_ axis: Configuration.Axis, step: Int, steps: Int) async throws {
        let backlashDegrees = axis.backlashAngle
        let startDegrees = axis.startAngle + backlashDegrees
        let endDegrees = axis.endAngle
        
        let startDistance = axis.angleToDistance(startDegrees).converted(to: .millimeters).value
        let endDistance = axis.angleToDistance(endDegrees).converted(to: .millimeters).value
        
        let stepDistance = (endDistance - startDistance) / Double(steps)
        let distance = startDistance + (stepDistance * Double(step))
        
        let angle = axis.distanceToAngle(Measurement(value: distance, unit: .millimeters))

//        let stepAngle = (endDegrees - startDegrees) / Double(steps)
//        let angle = startDegrees + (stepAngle * Double(step))
        try await robot.motorGoDirectionToPosition(
            port: axis.port,
            position: Int(angle.converted(to: .degrees).value.rounded()),
            direction: .shortest,
            speed: axis.speed,
            stall: true,
            stop: 0
        )
    }
}

extension Printer.Configuration.Axis {
    
    func angleToDistance(_ angle: Measurement<UnitAngle>) -> Measurement<UnitLength> {
        let angleRadians = angle.converted(to: .radians).value
        let camMillimeters = camLength.converted(to: .millimeters).value
        let distanceMillimeters = cos(angleRadians) * camMillimeters
        return Measurement(value: distanceMillimeters, unit: .millimeters)
    }
    
    func distanceToAngle(_ distance: Measurement<UnitLength>) -> Measurement<UnitAngle> {
        let distanceMillimeters = distance.converted(to: .millimeters).value
        let camMillimeters = camLength.converted(to: .millimeters).value
        let angleRadians = acos(distanceMillimeters / camMillimeters)
        return Measurement(value: angleRadians, unit: .radians)
    }

}
