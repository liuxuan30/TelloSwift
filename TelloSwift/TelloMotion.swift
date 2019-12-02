//
//  TelloMotion.swift
//  TelloSwift
//
//  Created by Xuan Liu on 2019/11/25.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//  Licensed under Apache License 2.0
//

import Foundation

public enum FlipDirection: String {
    case left = "l"
    case right = "r"
    case forward = "f"
    case back = "b"
}

public protocol TelloMotion: TelloCommander {
    var isEDU: Bool  { get }
    
    func takeoff() -> Bool
    
    func land() -> Bool
    
    func emergency() -> Bool

    func up(by x: Int) -> Bool

    func down(by x: Int) -> Bool

    func left(by x: Int) -> Bool

    func right(by x: Int) -> Bool

    func forward(by x: Int) -> Bool

    func back(by x: Int) -> Bool

    func cw(by x: Int) -> Bool

    func ccw(by x: Int) -> Bool

    func rotate(by x: Int, clockwise: Bool) -> Bool

    func flip(to direction: FlipDirection) -> Bool

    func hover() -> Bool

    func stop() -> Bool

    func go(to x: Int, y: Int, z: Int, speed: Int) -> Bool

    func curve(x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int, speed: Int) -> Bool

    func setSpeed(to speed: Int) -> Bool
}

public extension TelloMotion {
    
    @discardableResult
    func takeoff() -> Bool {
        return telloSyncCommand(cmd: "takeoff").okToBool()
    }
    
    @discardableResult
    func land() -> Bool {
        return telloSyncCommand(cmd: "land").okToBool()
    }
    
    @discardableResult
    func emergency() -> Bool {
        return telloSyncCommand(cmd: "emergency").okToBool()
    }
    
    @discardableResult
    func up(by x: Int) -> Bool {
        guard x >= 20 else { return false }
        return telloSyncCommand(cmd: "up \(x % 501)").okToBool()
    }
    
    @discardableResult
    func down(by x: Int) -> Bool {
        guard x >= 20 else { return false }
        return telloSyncCommand(cmd: "down \(x % 501)").okToBool()
    }

    @discardableResult
    func left(by x: Int) -> Bool {
        guard x >= 20 else { return false }
        return telloSyncCommand(cmd: "left \(x % 501)").okToBool()
    }

    @discardableResult
    func right(by x: Int) -> Bool {
        guard x >= 20 else { return false }
        return telloSyncCommand(cmd: "right \(x % 501)").okToBool()
    }

    @discardableResult
    func forward(by x: Int) -> Bool {
        guard x >= 20 else { return false }
        return telloSyncCommand(cmd: "forward \(x % 501)").okToBool()
    }

    @discardableResult
    func back(by x: Int) -> Bool {
        guard x >= 20 else { return false }
        return telloSyncCommand(cmd: "back \(x % 501)").okToBool()
    }

    @discardableResult
    func cw(by x: Int) -> Bool {
        return telloSyncCommand(cmd: "cw \(x % 361)").okToBool()
    }

    @discardableResult
    func ccw(by x: Int) -> Bool {
        return telloSyncCommand(cmd: "ccw \(x % 361)").okToBool()
    }

    @discardableResult
    func rotate(by x: Int, clockwise: Bool) -> Bool {
        return clockwise ? cw(by: x) : ccw(by: x)
    }

    @discardableResult
    func flip(to direction: FlipDirection) -> Bool {
        return telloSyncCommand(cmd: "flip \(direction.rawValue)").okToBool()
    }

    @discardableResult
    func hover() -> Bool {
        return telloSyncCommand(cmd: "stop").okToBool()
    }

    @discardableResult
    func stop() -> Bool {
        return hover()
    }

    @discardableResult
    func go(to x: Int, y: Int, z: Int, speed: Int) -> Bool {
        let distanceRange = -500...500
        let speedRange = 10...100
        guard
            distanceRange.contains(x),
            distanceRange.contains(y),
            distanceRange.contains(z),
            speedRange.contains(speed)
            else { return false }

        let innerRange = -20...20
        guard
            (innerRange.contains(x) && innerRange.contains(x) && innerRange.contains(x)) != true
            else {
                print("[TELLO] x, y, z fall in to [-20, 20] innerRange.contains(x)")
                return false
        }

        return telloSyncCommand(cmd: "go \(x) \(y) \(z) \(speed)").okToBool()
    }

    @discardableResult
    func curve(x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int, speed: Int) -> Bool {
        let distanceRange = -500...500
        let speedRange = 10...60
        guard
            distanceRange.contains(x1),distanceRange.contains(x2),
            distanceRange.contains(y1),distanceRange.contains(y2),
            distanceRange.contains(z1),distanceRange.contains(z2),
            speedRange.contains(speed)
            else { return false }

        let innerRange = -20...20
        guard
            (innerRange.contains(x1) && innerRange.contains(y1) && innerRange.contains(z1)) != true,
            (innerRange.contains(x2) && innerRange.contains(y2) && innerRange.contains(z2)) != true
            else {
                print("[TELLO] x, y, z fall in to [-20, 20] innerRange.contains(x)")
                return false
        }

        return telloSyncCommand(cmd: "curve \(x1) \(y1) \(z1) \(x2) \(y2) \(z2) \(speed)").okToBool()
    }

    @discardableResult
    func setSpeed(to speed: Int) -> Bool {
        return telloSyncCommand(cmd: "speed \(speed)").okToBool()
    }
}

extension Tello: TelloMotion {
    
}
