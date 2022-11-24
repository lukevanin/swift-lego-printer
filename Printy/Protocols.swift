//
//  MotorController.swift
//  Printy
//
//  Created by Luke Van In on 2022/11/22.
//

import Foundation


@MainActor protocol AngularMotorController {
    var angle: Measurement<UnitAngle> { get }
    var minimumAngle: Measurement<UnitAngle> { get }
    var maximumAngle: Measurement<UnitAngle> { get }
    func home() async throws
    func zero() async throws
    func move(to angle: Measurement<UnitAngle>) async throws
    func move(by angle: Measurement<UnitAngle>) async throws
}


@MainActor protocol LinearMotorController {
    var position: Measurement<UnitLength> { get }
    var minimumPosition: Measurement<UnitLength> { get }
    var maximumPosition: Measurement<UnitLength> { get }
    func home() async throws
    func zero() async throws
    func move(to position: Measurement<UnitLength>) async throws
    func move(by distance: Measurement<UnitLength>) async throws
}
