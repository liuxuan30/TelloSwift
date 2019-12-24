//
//  Tello.swift
//  TelloSwift
//
//  Created by Xuan on 2019/11/18.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//  Licensed under Apache License 2.0
//

import Foundation
import NIO

public enum FailoverOption {
    case land
    case hover
    case emergency
}

open class Tello {
    // MARK: Drone private variables
    var _isEDU: Bool = true
    
    // MARK: Mission pad variables
    var _missionPadDetectionEnabled: Bool!
    var _missionPadDirection: MissionPadDirection!
    
    // MARK: Commander protocol
    public var telloAddress = "192.168.10.1"
    
    // Tello IP: 192.168.10.1 UDP PORT:8889 <<- ->> PC/Mac/Mobile
    public var telloPort = 8889
    
    // Tello IP: 192.168.10.1 ->> PC/Mac/Mobile UDP Server: 0.0.0.0 UDP PORT:8890
    public var statePort = 8890
    
    public var localAddr: String
    public var localPort: Int
    
    var group: EventLoopGroup  // for test purpose as internal
    private var bootstrap: DatagramBootstrap
    public var commandChannel: Channel
    
    // MARK: Tello state channel
    private let stateChannel: Channel
    private let stateBootstrap: DatagramBootstrap
    
    // MARK: Tello video stream
    var _videoEnabled: Bool!
    
    private let videoChannel: Channel
    private let videoBootstrap: DatagramBootstrap
    
    // Tello IP: 192.168.10.1 ->> PC/Mac/Mobile UDP Server: 0.0.0.0 UDP PORT:11111
    public var videoPort = 11111

    weak public var stateDelegate: TelloState? {
        get {
            let h = try? stateChannel.pipeline.handler(type: TelloStateHandler.self).wait()
            return h?.delegate
        }
        set {
            let h = try? stateChannel.pipeline.handler(type: TelloStateHandler.self).wait()
            h?.delegate = newValue
        }
    }

    weak public var videoDelegate: TelloVideoSteam? {
        get {
            let h = try? videoChannel.pipeline.handler(type: TelloVideoHandler.self).wait()
            return h?.delegate
        }
        set {
            let h = try? videoChannel.pipeline.handler(type: TelloVideoHandler.self).wait()
            h?.delegate = newValue
        }
    }
    
    // MARK: functions
    deinit {
        print("[TELLO-FREE-]")
        if kaTimer != nil {
            print("[TELLO-FREE-] Detect timer in use yet invalidated")
            kaTimer!.invalidate()
        }
        if commandChannel.isActive {
            print("[TELLO-FREE-] MUST CALL shutdown() first, trying to close the channel only, event group may escape")
            commandChannel.close(mode: .all, promise: nil)
            stateChannel.close(mode: .all, promise: nil)
            videoChannel.close(mode: .all, promise: nil)
        }
    }
    
    public init(localAddr: String, localPort: Int) {
        self.localAddr = localAddr
        self.localPort = localPort
        group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        bootstrap = DatagramBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer({ channel in
                channel.pipeline.addHandler(TelloCommandHandler<CommandRequest, CommandResponse>())
            })
        commandChannel = try! bootstrap.bind(host: localAddr, port: localPort).wait()
        
        stateBootstrap = DatagramBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer({ channel in
                channel.pipeline.addHandler(TelloStateHandler())
            })
        
        // we don't care the state channel for now
        stateChannel = try! stateBootstrap.bind(host: "0.0.0.0", port: statePort).wait()
        
        videoBootstrap = DatagramBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer({ channel in
                channel.pipeline.addHandler(TelloVideoHandler())
            })
        
        videoChannel = try! videoBootstrap.bind(host: "0.0.0.0", port: videoPort).wait()
    }
    
    /// Initialize Tello with default 0.0.0.0 and a port
    /// - Parameter bindPort: Int
    public convenience init(port: Int) {
        self.init(localAddr: "0.0.0.0", localPort: port)
    }
    
    /// Initialize Tello with 0.0.0.0 and 6889
    public convenience init() {
        self.init(port: 6889)
    }
    
    public convenience init(localAddr: String, localPort: Int, EDU: Bool) {
        self.init(localAddr:localAddr, localPort: localPort)
        self._isEDU = EDU
    }
    
    public convenience init(port: Int, EDU: Bool) {
        self.init(port: port)
        self._isEDU = EDU
    }
    
    public convenience init(EDU: Bool) {
        self.init()
        self._isEDU = EDU
    }
    
    
    /// enter SDK mode by sending "command"
    public func activate() -> Bool {
        let ok = telloSyncCommand(cmd: "command")
        return ok == "ok"
    }
    
    var kaTimer: Timer?
    /// keep Tello alive by sending a command every 10 sec by default
    /// **USE AT YOUR OWN RISK**
    /// - Parameter interval: UInt32
    public func keepAlive(every interval: UInt32 = 10) {
        
        let date = Date().addingTimeInterval(TimeInterval(interval))
        
        if kaTimer == nil {
            kaTimer = Timer(fire: date, interval: TimeInterval(interval), repeats: true) { [weak self] t in
                if (self?.commandChannel.isActive ?? false) {
                    print(Date())
                    self?.telloAsyncCommand(cmd: "speed?", successHandler: nil, failureHandler: nil)
                }
            }
            RunLoop.main.add(kaTimer!, forMode: .common)
        }
    }
    
    /// Make sure you call this method on the same thread as keepAlive()
    public func invalidate() {
        kaTimer?.invalidate()
        kaTimer = nil
    }
    
    /// Only used in unit tests for now.
    func cleanup() {
        kaTimer?.invalidate()
        kaTimer = nil
        self.commandChannel.close(mode: .all, promise: nil)
        self.stateChannel.close(mode: .all, promise: nil)
        self.videoChannel.close(mode: .all, promise: nil)
        try! self.group.syncShutdownGracefully()
        print("[TELLO-DESTROYED-]")
    }

    @discardableResult
    public func chain(_ cmd: String, failover: FailoverOption?) -> Self? {
        var ok = telloSyncCommand(cmd: cmd).okToBool()
        if !ok && failover != nil {
            ok = self.failover(option: failover!)
        }
        return ok ? self : nil
    }

    @discardableResult
    public func chain(_ cmd: String) -> Self? {
        let ok = telloSyncCommand(cmd: cmd).okToBool()
        return ok ? self : nil
    }

    @discardableResult
    public func failover(option: FailoverOption = .land) -> Bool {
        var result: Bool
        switch option {
        case .hover:
            result = self.hover()
        case .land:
            result = self.land()
        case .emergency:
            result = self.emergency()
        }
        return result
    }
}

extension Tello: TelloCommander {
    
    /// Close each channel and shutdown the event group on main queue, *asynchronously*
    ///
    /// If you ever called keepAlive(), you should call invalidate() on the same thread before this method, or make sure you call shutdown() on the same thread as when you call keepAlive()
    public func shutdown() {
        // only invalidate timer in current thread
        kaTimer?.invalidate()
        kaTimer = nil
        DispatchQueue.main.async {
            self.commandChannel.close(mode: .all, promise: nil)
            self.stateChannel.close(mode: .all, promise: nil)
            self.videoChannel.close(mode: .all, promise: nil)
            try! self.group.syncShutdownGracefully()
            print("[TELLO-DESTROYED-]")
        }
    }
}
