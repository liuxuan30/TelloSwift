//
//  TelloFlightControl.swift
//  TelloSwift
//
//  Created by Xuan on 2019/11/27.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//  Licensed under Apache License 2.0
//

import Foundation

public protocol TelloFlightControl: TelloMotion {
    
    func takeoffAnd(operation: @escaping () -> Void)
    
    func takeoffAnd(do cmd: String) -> Bool
    
    func beforeLand(after shutdown: Bool, do operation: () -> Void)
    
    func beforeLand(do cmd: String, after shutdown: Bool) -> Bool
}

extension Tello: TelloFlightControl {
    
    public func takeoffAnd(operation: @escaping () -> Void) {
        telloAsyncCommand(cmd: "takeoff", successHandler: { state in
            if let ok = state?.okToBool(), ok {
                operation()
            }
        }) {
            print("take off failed due to \($0), abort mission")
        }
    }
    
    @discardableResult
    public func takeoffAnd(do cmd: String) -> Bool {
        if takeoff() {
            return telloSyncCommand(cmd: cmd).okToBool()
        } else {
            print("take off failed, abort mission")
            return false
        }
    }
    
    public func beforeLand(after shutdown: Bool, do operation: () -> Void) {
        defer { if shutdown { self.shutdown() } }
        operation()
        land()
    }
    
    @discardableResult
    public func beforeLand(do cmd: String, after shutdown: Bool) -> Bool {
        defer { if shutdown { self.shutdown() } }
        let ok = telloSyncCommand(cmd: cmd).okToBool()
        return ok && land()
    }
}
