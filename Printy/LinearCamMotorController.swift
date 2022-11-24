//
//  LinearCamController.swift
//  Printy
//
//  Created by Luke Van In on 2022/11/22.
//

import Foundation
import OSLog


private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "LinearCamMotor")


@MainActor final class LinearCamMotorController: LinearMotorController {
    
    var position: Measurement<UnitLength> {
        angleToDistance(motor.angle)
    }
    
    let minimumPosition: Measurement<UnitLength>
    let maximumPosition: Measurement<UnitLength>
    
    private let camLength: Measurement<UnitLength>
    private let motor: AngularMotorController
    
    init(camLength: Measurement<UnitLength>, motor: AngularMotorController) {
        self.camLength = camLength
        self.motor = motor
        self.minimumPosition = Measurement(value: -camLength.value, unit: camLength.unit)
        self.maximumPosition = Measurement(value: +camLength.value, unit: camLength.unit)
    }
    
    func home() async throws {
        try await motor.zero()
    }
    
    func zero() async throws {
        try await motor.zero()
    }
    
    func move(to position: Measurement<UnitLength>) async throws {
        #warning("TODO: Clamp position to 0...cam_length * 2")
        logger.info("Moving to \(position.converted(to: .millimeters))")
        let angle = distanceToAngle(position)
        try await motor.move(to: angle)
    }

    func move(by distance: Measurement<UnitLength>) async throws {
        logger.info("Moving by \(distance.converted(to: .millimeters))")
        let position = self.position + distance
        let angle = distanceToAngle(position)
        try await motor.move(to: angle)
    }

    private func angleToDistance(_ angle: Measurement<UnitAngle>) -> Measurement<UnitLength> {
        let angleRadians = angle.converted(to: .radians).value
        let camMillimeters = camLength.converted(to: .millimeters).value
        let distanceMillimeters = -cos(angleRadians) * camMillimeters
        return Measurement(value: distanceMillimeters, unit: .millimeters)
    }

    private func distanceToAngle(_ distance: Measurement<UnitLength>) -> Measurement<UnitAngle> {
        var distanceMillimeters = -distance.converted(to: .millimeters).value
        distanceMillimeters = max(distanceMillimeters, minimumPosition.converted(to: .millimeters).value)
        distanceMillimeters = min(distanceMillimeters, maximumPosition.converted(to: .millimeters).value)
        let camMillimeters = camLength.converted(to: .millimeters).value
        let angleRadians = acos(distanceMillimeters / camMillimeters)
        return Measurement(value: angleRadians, unit: .radians)
    }
}
