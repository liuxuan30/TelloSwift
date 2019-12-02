//
//  DroneTello.swift
//  TelloSwift
//
//  Created by Xuan on 2019/11/23.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//  Licensed under Apache License 2.0
//

import Foundation

public protocol DroneTello {

    /// Get/Set current speed in cm/s, range [0, 100.0]
    ///
    /// raw data example: 100.0
    var speed: Double { get set }
    
    /// current height in cm, range [0, 3000]
    ///
    /// raw data example: 15dm
    ///
    /// It's strange the official SDK documentation specifies as cm,
    /// but the value returned is in dm
    var height: Double { get }
    
    /// flying duration in second
    ///
    /// raw data example: 11s
    var time: Double { get }
    
    /// in °C, range [0, 90]
    ///
    /// raw data example: 85~88C
    var temperature: String { get }
    var minTemp: Double { get }
    var maxTemp: Double { get }
    
    /// in perentage, range [0-100]
    ///
    /// raw data example: 87
    var battery: Double { get }
    
    /// IMU attitude data, degree
    ///
    /// raw data example: pitch:0;roll:-1;yaw:0;
    var attitude: String { get }
    var pitch: Double { get }
    var roll: Double { get }
    var yaw: Double { get }
    
    /// acceleration data
    ///
    /// raw data example: agx:-5.00;agy:7.00;agz:-999.00;
    var acceleration: String { get }
    var agx: Double { get }
    var agy: Double {get }
    var agz: Double {get }
    
    /// barometer value (m)
    ///
    /// raw data example: -102.865509
    var baro: Double { get }
    
    /// distance value from TOF in cm
    ///
    /// raw data example: 875mm
    ///
    /// It's strange the official SDK documentation specifies as cm,
    /// but the value returned is in mm
    var tof: Double { get }
    
    /// WIFI signal noise ratio(SNR)
    /// raw data example: 90
    var wifiSNR: Double { get }
}

extension Tello: DroneTello {
    
    public var speed: Double {
        get {
            return telloSyncCommand(cmd: "speed?").toDouble()
        }
        set {
            let r = telloSyncCommand(cmd: "speed \(newValue)")
            print("[TELLO DEBUG] set speed to \(newValue):", r)
        }
    }
    
    public var height: Double {
        let h = telloSyncCommand(cmd: "height?").toDouble()
        return h != Double.nan ? h * 10 : h
    }
    
    public var time: Double {
        return telloSyncCommand(cmd: "time?").toDouble()
    }
    
    public var temperature: String {
        return telloSyncCommand(cmd: "temp?")
    }
    
    public var minTemp: Double {
        let range = temperature.components(separatedBy: "~")
        guard range.count > 0 else { return Double.nan }
        return range[0].toDouble()
    }
    
    public var maxTemp: Double {
        let range = temperature.components(separatedBy: "~")
        guard range.count > 1 else { return Double.nan }
        return range[1].toDouble()
    }
    
    public var battery: Double {
        return telloSyncCommand(cmd: "battery?").toDouble()
    }
    
    public var attitude: String {
        return telloSyncCommand(cmd: "attitude?")
    }

    public var pitch: Double {
        let att = attitude.components(separatedBy: ";")
        return att.count > 0 ? att[0].toDouble() : Double.nan
    }

    public var roll: Double {
        let att = attitude.components(separatedBy: ";")
        return att.count > 1 ? att[1].toDouble() : Double.nan
    }

    public var yaw: Double {
        let att = attitude.components(separatedBy: ";")
        return att.count > 2 ? att[2].toDouble() : Double.nan
    }
    
    public var acceleration: String {
        return telloSyncCommand(cmd: "acceleration?")
    }

    public var agx: Double {
        let acc = acceleration.components(separatedBy: ";")
        return acc.count > 0 ? acc[0].toDouble() : Double.nan
    }

    public var agy: Double {
        let acc = acceleration.components(separatedBy: ";")
        return acc.count > 1 ? acc[1].toDouble() : Double.nan
    }

    public var agz: Double {
        let acc = acceleration.components(separatedBy: ";")
        return acc.count > 2 ? acc[2].toDouble() : Double.nan
    }
    
    public var baro: Double {
        return telloSyncCommand(cmd: "baro?").toDouble()
    }
    
    public var tof: Double {
        return telloSyncCommand(cmd: "tof?").toDouble()
    }
    
    public var wifiSNR: Double {
        return telloSyncCommand(cmd: "wifi?").toDouble()
    }
}
