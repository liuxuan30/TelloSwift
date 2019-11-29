//
//  CameraControl.swift
//  TelloSwift
//
//  Created by Xuan on 2019/11/23.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//

import Foundation

public protocol CameraControl: TelloCommander {
    
    func enable(video enable: Bool) -> Bool
}

extension CameraControl {
    
    public func enable(video enable: Bool) -> Bool {
        let op = enable ? "streamon" : "streamoff"
        let ok = telloSyncCommand(cmd: op).okToBool()
        print("[TELLO] Enabled video stream:", ok)
        return ok
    }
}

extension Tello: CameraControl {
    
    public var videoEnabled: Bool? {
        get {
            return _videoEnabled
        }
        set {
            guard let val = newValue else { return }
            if enable(video: val) {
                _videoEnabled = val
            }
        }
    }
    
}
