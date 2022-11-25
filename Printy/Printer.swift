import Foundation
import OSLog

import SwiftMindstorms

import PrintySDK


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

    
    // MARK: State
    
//    private class AnyState {
//        unowned var context: Printer!
//
//        func enter() { }
//    }
    
    // MARK: Variables
    
    private var printing = false
//    private var axisDistance = [MotorPort : Int]()
    
    private var xAxisController: LinearMotorController!
    private var yAxisController: LinearMotorController!
    private var robot: Robot!
    private var configuration: Configuration!
    
    // MARK: Methods
    
    init(configuration: Configuration) {
        Task {
            let connection = await BluetoothConnection()
            let hub = await Hub(connection: connection)
            let robot = await Robot(orientation: .left, hub: hub)
            self.robot = robot
            self.configuration = configuration
            self.xAxisController = LinearBacklashMotorController(
                backlash: Measurement(value: 3, unit: .millimeters),
                motor: LinearCamMotorController(
                    camLength: configuration.xAxis.camLength,
                    motor: GearedMotorController(
                        ratio: 24.0,
                        motor: DirectMotorController(
                            port: configuration.xAxis.motor.port,
                            speed: configuration.xAxis.motor.speed,
                            robot: robot
                        )
                    )
                )
            )
            self.yAxisController = LinearBacklashMotorController(
                backlash: Measurement(value: 3, unit: .millimeters),
                motor: LinearCamMotorController(
                    camLength: configuration.yAxis.camLength,
                    motor: GearedMotorController(
                        ratio: 24.0,
                        motor: DirectMotorController(
                            port: configuration.yAxis.motor.port,
                            speed: configuration.yAxis.motor.speed,
                            robot: robot
                        )
                    )
                )
            )
        }
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
                try await xAxisController.zero()
                try await yAxisController.zero()
                try await zeroPen()
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
    
    func rangeXAxis() {
        Task {
            do {
                try await rangeAxis(xAxisController)
            }
            catch {
                logger.error("Cannot range X axis \(error.localizedDescription)")
            }
        }
    }
    
    func rangeYAxis() {
        Task {
            do {
                try await rangeAxis(yAxisController)
            }
            catch {
                logger.error("Cannot range Y axis \(error.localizedDescription)")
            }
        }
    }

    func test() {
        let image = Image.checker13x13
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
        try await zeroPen()
        guard printing == true else {
            return
        }
        try await yAxisController.home()
        for y in 0 ..< count {
            guard printing == true else {
                return
            }
            try await stepAxis(yAxisController, step: y, steps: count)
            let row = image.pixels[y]
            guard printing == true else {
                return
            }
            if row.contains(.x) == true {
                try await plotRow(row)
            }
        }
        try await xAxisController.zero()
        try await yAxisController.zero()
    }
    
    private func plotRow(_ row: [Image.Element]) async throws {
        guard printing == true else {
            return
        }
        let count = row.count
        try await xAxisController.home()
        for x in 0 ..< count {
            guard printing == true else {
                return
            }
            try await stepAxis(xAxisController, step: x, steps: count)
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

    private func zeroPen() async throws {
        let axis = configuration.penAxis
        try await robot.motorGoDirectionToPosition(
            port: axis.motor.port,
            position: Int(axis.startAngle.converted(to: .degrees).value.rounded()),
            direction: .shortest,
            speed: axis.motor.speed,
            stall: true,
            stop: 0
        )
    }

//    private func homeAxis(_ axis: Configuration.GearAxis) async throws {
//        try await zeroAxis(axis)
//        try await moveAxis(axis, angle: axis.backlash * Double(axis.ratio))
//        try await moveAxis(axis, angle: axis.resolution * Double(+axis.ratio))
//        try await moveAxis(axis, angle: axis.resolution * Double(-axis.ratio))
//    }
    
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
    
    private func rangeAxis(_ axis: LinearMotorController) async throws {
        try await axis.move(to: axis.minimumPosition)
        try await axis.move(to: axis.maximumPosition)
        try await axis.move(to: axis.minimumPosition)
    }
    
    private func stepAxis(_ axis: LinearMotorController, step: Int, steps: Int) async throws {
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

//        let startAngle = axis.backlash
//        let endAngle = axis.resolution
//
//        let startDistance = axis.angleToDistance(startAngle).converted(to: .millimeters).value
//        let endDistance = axis.angleToDistance(endAngle).converted(to: .millimeters).value
//
//        let stepDistance = (endDistance - startDistance) / Double(steps)
//        let distance = startDistance + (stepDistance * Double(step))
//
//        let targetAngle = axis.distanceToAngle(Measurement(value: distance, unit: .millimeters)).converted(to: .degrees).value
//        let currentAngle = Double(axisDistance[axis.motor.port, default: 0]) / Double(axis.ratio)
//        let stepAngle = Measurement<UnitAngle>(value: targetAngle - currentAngle, unit: .degrees)

//        let step
//        let stepAngle = (endDegrees - startDegrees) / Double(steps)
        

//        print("Step", step, "out of", steps)
//        print("Start Angle", startDegrees)
//        print("End Angle", endDegrees)
//        print("Step Angle", stepAngle)
//        print("Start Distance", startDistance)
//        print("End Distance", endDistance)
//        print("Step Distance", stepDistance)
//        print("Step Angle", stepAngle)

        let minPosition = axis.minimumPosition
        let maxPosition = axis.maximumPosition
        let stepSize = (maxPosition - minPosition) / Double(steps)
        
        try await axis.move(by: stepSize)
    }
    
//    private func moveAxis(_ axis: Configuration.GearAxis, angle: Measurement<UnitAngle>) async throws {
//
//        let angleDegrees = Int(angle.converted(to: .degrees).value.rounded())
//
//        axisDistance[axis.motor.port, default: 0] += angleDegrees
//
//        try await robot.motorRunForDegrees(
//            port: axis.motor.port,
//            degrees: angleDegrees,
//            speed: axis.motor.speed,
//            stall: true
//        )
//
//    }
}
