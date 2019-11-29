//
//  EDU.swift
//  TelloSwift
//
//  Created by Xuan Liu on 2019/11/26.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//

import Foundation

public protocol EDU {

    var isEDU: Bool { get }

    /// Serial Number, Only available for TELLO SDK 2.0
    ///
    /// raw data example: 0TQDG7REDB65P9
    var sn: String? { get }

    /// SDK version, Only available for TELLO SDK 2.0
    ///
    /// raw data example: 20
    var sdkVersion: String? { get }
}

extension Tello: EDU {
    public var isEDU: Bool {
        return _isEDU
    }
    
    public var sn: String? {
        guard isEDU else { return nil }
        return telloSyncCommand(cmd: "sn?")
    }
    
    public var sdkVersion: String? {
        guard isEDU else { return nil }
        return telloSyncCommand(cmd: "sdk?")
    }
}
