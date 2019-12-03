//
//  MissionPadControl.swift
//  TelloSwift
//
//  Created by Xuan Liu on 2019/11/26.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//  Licensed under Apache License 2.0
//

import Foundation

public enum MissionPadID: String {
    case m1
    case m2
    case m3
    case m4
    case m5
    case m6
    case m7
    case m8
}

public enum MissionPadDirection: Int {
    case downward = 0
    case forward
    case both
}

public protocol MissionPadControl: EDU, TelloCommander {

    func enable(detection enable: Bool) -> Bool

    func setDirection(direction: MissionPadDirection) -> Bool

    func go(mid: MissionPadID, x: Int, y: Int, z: Int, speed: Int) -> Bool

    func curve(mid: MissionPadID, x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int, speed: Int) -> Bool

    func jump(mid1: MissionPadID, mid2: MissionPadID, x: Int, y: Int, z: Int, speed: Int, yaw: Int) -> Bool
}

public extension MissionPadControl  {

    func enable(detection enable: Bool) -> Bool {
        let op = enable ? "mon" : "moff"
        let ok = telloSyncCommand(cmd: op).okToBool()
        print("[TELLO] Enabled mission pad:", ok)
        return ok
    }

    func setDirection(direction: MissionPadDirection) -> Bool {
        let ok = telloSyncCommand(cmd: "mdirection \(direction.rawValue)").okToBool()
        print("[TELLO] Mission pad direction set to \(direction.rawValue):", ok)
        return ok
    }

    @discardableResult
    func go(mid: MissionPadID, x: Int, y: Int, z: Int, speed: Int) -> Bool {
        guard isEDU else { return false }
        
        let valid = validate(speed: speed, distances: [x, y, z], speedRange: 10...100)
        guard valid else {
            print("[TELLO] speed or distance don't satisfy. Either out of range or x, y, z all fall in [-20, 20]")
            return false
        }

        return telloSyncCommand(cmd: "go \(x) \(y) \(z) \(speed) \(mid.rawValue)").okToBool()
    }

    @discardableResult
    func curve(mid: MissionPadID, x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int, speed: Int) -> Bool {
        guard isEDU else { return false }

        let valid = validate(speed: speed, distances: [x1, y1, z1]) &&
            validate(speed: nil, distances: [x2, y2, z2])
        
        guard valid else {
            print("[TELLO] speed or distance don't satisfy. Either out of range or x, y, z all fall in [-20, 20]")
            return false
        }
        return telloSyncCommand(cmd: "curve \(x1) \(y1) \(z1) \(x2) \(y2) \(z2) \(speed) \(mid.rawValue)").okToBool()
    }

    @discardableResult
    func jump(mid1: MissionPadID, mid2: MissionPadID, x: Int, y: Int, z: Int, speed: Int, yaw: Int) -> Bool {
        guard isEDU else { return false }
        
        let valid = validate(speed: speed, distances: [x, y, z], speedRange: 10...100)
        guard valid else {
            print("[TELLO] speed or distance don't satisfy. Either out of range or x, y, z all fall in [-20, 20]")
            return false
        }

        return telloSyncCommand(cmd: "go \(x) \(y) \(z) \(speed) \(yaw) \(mid1.rawValue) \(mid2.rawValue)").okToBool()
    }
}

extension Tello: MissionPadControl {
    
    public var detectionEnabled: Bool? {
        get {
            return _missionPadDetectionEnabled ?? nil
        }
        set {
            guard let val = newValue else { return }
            if enable(detection: val) {
                _missionPadDetectionEnabled = val
            }
        }
    }
    
    public var direction: MissionPadDirection? {
        get {
            return _missionPadDirection ?? nil
        }
        set {
            guard let direct = newValue else { return }
            if setDirection(direction: direct) {
                _missionPadDirection = direct
            }
        }
    }
}

