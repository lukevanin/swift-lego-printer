//
//  LinearBacklashMotorController.swift
//  Printy
//
//  Created by Luke Van In on 2022/11/23.
//

import Foundation
import OSLog


private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "LinearBacklashMotor")


@MainActor final class LinearBacklashMotorController: LinearMotorController {
    
    var position: Measurement<UnitLength> {
        motor.position
    }
    
    let minimumPosition: Measurement<UnitLength>
    let maximumPosition: Measurement<UnitLength>
    
    private let backlash: Measurement<UnitLength>
    private let motor: LinearMotorController
    
    init(backlash: Measurement<UnitLength>, motor: LinearMotorController) {
        self.backlash = backlash
        self.motor = motor
        self.minimumPosition = motor.minimumPosition + backlash
        self.maximumPosition = motor.maximumPosition
    }
    
    func home() async throws {
        try await motor.zero()
        try await motor.move(to: minimumPosition)
    }
    
    func zero() async throws {
        try await motor.zero()
    }
    
    func move(by distance: Measurement<UnitLength>) async throws {
        logger.info("Move by \(distance.converted(to: .millimeters))")
        guard distance > Measurement(value: 0, unit: .millimeters) else {
            return
        }
        try await motor.move(by: distance)
    }
    
    func move(to position: Measurement<UnitLength>) async throws {
        logger.info("Move to \(position.converted(to: .millimeters))")
        guard position > self.position else {
            return
        }
        let position = min(max(position, minimumPosition), maximumPosition)
        try await motor.move(to: position)
    }
}
