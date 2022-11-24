//
//  DirectMotorController.swift
//  Printy
//
//  Created by Luke Van In on 2022/11/22.
//

import Foundation
import OSLog

import SwiftMindstorms


private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "GearedMotor")


@MainActor final class DirectMotorController: AngularMotorController {
    
    var angle: Measurement<UnitAngle> {
        Measurement(value: Double(degrees), unit: .degrees)
    }
    
    let minimumAngle: Measurement<UnitAngle>
    let maximumAngle: Measurement<UnitAngle>
    
    private var degrees: Int = 0
    
    private let port: MotorPort
    private let speed: Int
    private let robot: Robot
    
    init(port: MotorPort, speed: Int, robot: Robot) {
        self.port = port
        self.speed = speed
        self.robot = robot
        self.minimumAngle = Measurement(value: 0, unit: .degrees)
        self.maximumAngle = Measurement(value: 359, unit: .degrees)
    }
    
    func home() async throws {
        try await zero()
    }
    
    func zero() async throws {
        try await move(degrees: -degrees)
    }

    func move(to angle: Measurement<UnitAngle>) async throws {
        logger.info("Moving to angle \(angle.converted(to: .degrees))")
        let degrees = Int(angle.converted(to: .degrees).value.rounded())
        let delta = degrees - self.degrees
        try await move(degrees: delta)
    }
    
    func move(by angle: Measurement<UnitAngle>) async throws {
        logger.info("Moving by angle \(angle.converted(to: .degrees))")
        let degrees = Int(angle.converted(to: .degrees).value.rounded())
        try await move(degrees: degrees)
    }

    private func move(degrees: Int) async throws {
        try await robot.motorRunForDegrees(
            port: port,
            degrees: degrees,
            speed: speed,
            stall: true
        )
        self.degrees += degrees
    }

}
