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

func validate(speed: Int?, distances: [Int]?, speedRange: ClosedRange<Int> = 10...60, distanceRange: ClosedRange<Int> = -500...500, innerRange: ClosedRange<Int> = -20...20) -> Bool {
    var valid = false
    if let s = speed {
        valid = speedRange.contains(s)
    }
    
    var allInside = true
    if let dist = distances {
        for d in dist {
            valid = distanceRange.contains(d)
            if !valid { break }
            allInside = allInside && innerRange.contains(d)
        }
    }
    
    return (distances == nil || distances?.count == 0) ? valid : valid && !allInside
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
        let valid = validate(speed: speed, distances: [x, y, z], speedRange: 10...100)
        guard valid else {
            print("[TELLO] speed or distance don't satisfy. Either out of range or x, y, z all fall in [-20, 20]")
            return false
        }
        return telloSyncCommand(cmd: "go \(x) \(y) \(z) \(speed)").okToBool()
    }

    @discardableResult
    func curve(x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int, speed: Int) -> Bool {
        let valid = validate(speed: speed, distances: [x1, y1, z1]) &&
            validate(speed: nil, distances: [x2, y2, z2])
        
        guard valid else {
            print("[TELLO] speed or distance don't satisfy. Either out of range or x, y, z all fall in [-20, 20]")
            return false
        }
        return telloSyncCommand(cmd: "curve \(x1) \(y1) \(z1) \(x2) \(y2) \(z2) \(speed)").okToBool()
    }

    @discardableResult
    func setSpeed(to speed: Int) -> Bool {
        let valid = validate(speed: speed, distances: nil, speedRange: 10...100)
        guard valid else { return false }
        return telloSyncCommand(cmd: "speed \(speed)").okToBool()
    }
}

extension Tello: TelloMotion {
    
}
