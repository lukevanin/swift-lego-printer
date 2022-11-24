//
//  GearedMotorController.swift
//  Printy
//
//  Created by Luke Van In on 2022/11/22.
//

import Foundation
import OSLog


private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "GearedMotor")


@MainActor final class GearedMotorController: AngularMotorController {
    
    // Angle of the output shaft: 0...359 degrees
    var angle: Measurement<UnitAngle> {
        motor.angle / ratio
    }
    
    let minimumAngle: Measurement<UnitAngle>
    let maximumAngle: Measurement<UnitAngle>

    private let ratio: Double
    private let motor: AngularMotorController

    init(ratio: Double, motor: AngularMotorController) {
        self.ratio = ratio
        self.motor = motor
        self.minimumAngle = motor.minimumAngle / ratio
        self.maximumAngle = motor.maximumAngle / ratio
    }
    
    func home() async throws {
        try await motor.home()
    }
    
    func zero() async throws {
        try await motor.zero()
    }
    
    // Moves the output to the given angle.
    func move(to angle: Measurement<UnitAngle>) async throws {
        logger.info("Moving to angle \(angle.converted(to: .degrees))")
        let deltaAngle = angle - self.angle
        try await motor.move(by: deltaAngle * ratio)
    }
    
    // Moves the output by the given angle.
    func move(by angle: Measurement<UnitAngle>) async throws {
        logger.info("Moving by angle \(angle.converted(to: .degrees))")
        try await motor.move(by: angle * ratio)
    }
    
}
