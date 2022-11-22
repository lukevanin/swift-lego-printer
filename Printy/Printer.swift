import Foundation
import OSLog

import SwiftMindstorms


private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Printer")


@MainActor final class Printer {
    
    // MARK: Configuration
    
    struct Configuration {
        
        struct Motor {
            var port: MotorPort
            var speed: Int
        }
        
        struct GearAxis {
            var motor: Motor
            var ratio: Int
            var camLength: Measurement<UnitLength>
            var resolution: Measurement<UnitAngle>
            var backlash: Measurement<UnitAngle>
        }

        struct CamAxis {
            var motor: Motor
            var camLength: Measurement<UnitLength>
            var startAngle: Measurement<UnitAngle>
            var endAngle: Measurement<UnitAngle>
            var backlashAngle: Measurement<UnitAngle>
        }

        var xAxis: GearAxis
        var yAxis: GearAxis
        var penAxis: CamAxis
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

//        static let test = Image(width: 17, height: 17)

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
    private var axisDistance = [MotorPort : Int]()
    
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
                try await zeroAxis(configuration.xAxis)
                try await zeroAxis(configuration.yAxis)
                try await zeroAxis(configuration.penAxis)
            }
            catch {
                logger.error("Cannot home printer \(error.localizedDescription)")
            }
        }
    }
    
    func controlXAxis(direction: Int) {
        Task {
            do {
                try await self.controlAxis(configuration.xAxis, direction: direction)
            }
            catch {
                logger.error("Cannot control X axis \(error.localizedDescription)")
            }
        }
    }
    
    func controlYAxis(direction: Int) {
        Task {
            do {
                try await self.controlAxis(configuration.yAxis, direction: direction)
            }
            catch {
                logger.error("Cannot control Y axis \(error.localizedDescription)")
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

    func plot(_ image: Image) {
        Task {
            guard printing == false else {
                return
            }
            printing = true
            do {
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
        try await zeroAxis(configuration.penAxis)
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
        try await zeroAxis(configuration.xAxis)
        try await zeroAxis(configuration.yAxis)
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
            port: axis.motor.port,
            position: Int(axis.endAngle.converted(to: .degrees).value.rounded()),
            direction: .shortest,
            speed: axis.motor.speed,
            stall: true,
            stop: 0
        )
        try await robot.motorGoDirectionToPosition(
            port: axis.motor.port,
            position: Int(axis.startAngle.converted(to: .degrees).value.rounded()),
            direction: .shortest,
            speed: axis.motor.speed,
            stall: true,
            stop: 0
        )
    }

    private func zeroAxis(_ axis: Configuration.CamAxis) async throws {
        try await robot.motorGoDirectionToPosition(
            port: axis.motor.port,
            position: Int(axis.startAngle.converted(to: .degrees).value.rounded()),
            direction: .shortest,
            speed: axis.motor.speed,
            stall: true,
            stop: 0
        )
    }

    private func homeAxis(_ axis: Configuration.GearAxis) async throws {
        try await zeroAxis(axis)
        try await moveAxis(axis, angle: axis.backlash * Double(axis.ratio))
//        try await moveAxis(axis, angle: axis.resolution * Double(+axis.ratio))
//        try await moveAxis(axis, angle: axis.resolution * Double(-axis.ratio))
    }
    
    private func zeroAxis(_ axis: Configuration.GearAxis) async throws {
        guard let angleDegrees = axisDistance.removeValue(forKey: axis.motor.port) else {
            return
        }
        try await robot.motorRunForDegrees(
            port: axis.motor.port,
            degrees: -angleDegrees,
            speed: axis.motor.speed,
            stall: true
        )
    }
    
    private func controlAxis(_ axis: Configuration.GearAxis, direction: Int) async throws {
        if direction == 0 {
            try await robot.motorStop(
                port: axis.motor.port,
                stop: 0
            )
        }
        else {
            try await robot.motorStart(
                port: axis.motor.port,
                speed: axis.motor.speed * direction,
                stall: true
            )
        }
    }
    
    private func stepAxis(_ axis: Configuration.GearAxis, step: Int, steps: Int) async throws {
//        let backlashDegrees = axis.backlashAngle
//        let startDegrees = axis.startAngle + backlashDegrees
//        let endDegrees = axis.endAngle
//
//        let startDistance = axis.angleToDistance(startDegrees).converted(to: .millimeters).value
//        let endDistance = axis.angleToDistance(endDegrees).converted(to: .millimeters).value
//
//        let stepDistance = (endDistance - startDistance) / Double(steps)
//        let distance = startDistance + (stepDistance * Double(step))
//
//        let angle = axis.distanceToAngle(Measurement(value: distance, unit: .millimeters))

//        let stepAngle = (endDegrees - startDegrees) / Double(steps)
//        let angle = startDegrees + (stepAngle * Double(step))
//        try await robot.motorGoDirectionToPosition(
//            port: axis.port,
//            position: Int(angle.converted(to: .degrees).value.rounded()),
//            direction: .shortest,
//            speed: axis.speed,
//            stall: true,
//            stop: 0
//        )

//        let startDegrees = axis.backlash * Double(axis.ratio)
//        let endDegrees = axis.resolution * Double(axis.ratio)
//
//        let stepAngle = (endDegrees - startDegrees) / Double(steps)

        let startAngle = axis.backlash
        let endAngle = axis.resolution
        
        let startDistance = axis.angleToDistance(startAngle).converted(to: .millimeters).value
        let endDistance = axis.angleToDistance(endAngle).converted(to: .millimeters).value

        let stepDistance = (endDistance - startDistance) / Double(steps)
        let distance = startDistance + (stepDistance * Double(step))
        
        let targetAngle = axis.distanceToAngle(Measurement(value: distance, unit: .millimeters)).converted(to: .degrees).value
        let currentAngle = Double(axisDistance[axis.motor.port, default: 0]) / Double(axis.ratio)
        let stepAngle = Measurement<UnitAngle>(value: targetAngle - currentAngle, unit: .degrees)

//        let step
//        let stepAngle = (endDegrees - startDegrees) / Double(steps)

        print("Step", step, "out of", steps)
//        print("Start Angle", startDegrees)
//        print("End Angle", endDegrees)
//        print("Step Angle", stepAngle)
        print("Start Distance", startDistance)
        print("End Distance", endDistance)
        print("Step Distance", stepDistance)
        print("Step Angle", stepAngle)


        try await moveAxis(axis, angle: stepAngle * Double(axis.ratio))
    }
    
    private func moveAxis(_ axis: Configuration.GearAxis, angle: Measurement<UnitAngle>) async throws {
        
        let angleDegrees = Int(angle.converted(to: .degrees).value.rounded())
        
        axisDistance[axis.motor.port, default: 0] += angleDegrees

        try await robot.motorRunForDegrees(
            port: axis.motor.port,
            degrees: angleDegrees,
            speed: axis.motor.speed,
            stall: true
        )

    }
}

extension Printer.Configuration.GearAxis {

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
