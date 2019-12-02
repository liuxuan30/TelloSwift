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

        return telloSyncCommand(cmd: "go \(x) \(y) \(z) \(speed) \(mid.rawValue)").okToBool()
    }

    @discardableResult
    func curve(mid: MissionPadID, x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int, speed: Int) -> Bool {
        guard isEDU else { return false }
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

        return telloSyncCommand(cmd: "curve \(x1) \(y1) \(z1) \(x2) \(y2) \(z2) \(speed) \(mid.rawValue)").okToBool()
    }

    @discardableResult
    func jump(mid1: MissionPadID, mid2: MissionPadID, x: Int, y: Int, z: Int, speed: Int, yaw: Int) -> Bool {
        guard isEDU else { return false }
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

