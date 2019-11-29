//
//  TelloCommander.swift
//  TelloSwift
//
//  Created by Xuan on 2019/11/23.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//

import Foundation
import NIO

public typealias CommandRequest = AddressedEnvelope<ByteBuffer>
public typealias CommandResponse = AddressedEnvelope<ByteBuffer>

public protocol TelloCommander {
    // Send Command & Receive Response
    var telloAddress: String { get }
    
    // Tello IP: 192.168.10.1 UDP PORT:8889 <<- ->> PC/Mac/Mobile
    var telloPort: Int { get }
    
    // Tello IP: 192.168.10.1 ->> PC/Mac/Mobile UDP Server: 0.0.0.0 UDP PORT:8890
    var statePort: Int { get }
    
    var localAddr: String { get }
    var localPort: Int { get }
    
    var commandChannel: Channel { get }

    /// Clean up any resource if needed here
    func shutdown()
    
    func dispatchCommand(cmd: String, remoteAddr: String, remotePort: Int) throws -> EventLoopFuture<CommandResponse>
    func syncSendCommand(cmd: String, remoteAddr: String, remotePort: Int) throws -> String
    func asyncSendCommand(cmd: String, remoteAddr: String, remotePort: Int, successHandler: ((String?) -> Void)?, failureHandler: ((Error) -> Void)? )
    func telloSyncCommand(cmd: String) -> String
    func telloAsyncCommand(cmd: String, successHandler: ((String?) -> Void)?, failureHandler: ((Error) -> Void)? )
}

public extension TelloCommander {
    func shutdown() {
        self.commandChannel.close(mode: .all, promise: nil)
    }
    
    func dispatchCommand(cmd: String, remoteAddr: String, remotePort: Int) throws -> EventLoopFuture<CommandResponse> {
        let socketAddr = try SocketAddress(ipAddress: remoteAddr, port: remotePort)
        
        var buffer = commandChannel.allocator.buffer(capacity: 128)
        buffer.writeString(cmd)
        let envelope = AddressedEnvelope(remoteAddress: socketAddr, data: buffer)
        let responsePromise = commandChannel.eventLoop.makePromise(of: CommandResponse.self)
        
        commandChannel.writeAndFlush((envelope, responsePromise), promise: nil);
        return responsePromise.futureResult
    }
    
    func syncSendCommand(cmd: String, remoteAddr: String, remotePort: Int) throws -> String {
        do {
            let future = try dispatchCommand(cmd: cmd, remoteAddr: remoteAddr, remotePort: remotePort)
            var data = try future.wait().data
            return data.readString(length: data.readableBytes) ?? ""
        } catch {
            print("[TELLO]-SYNC CMD- encounter error:", error)
            throw error
        }
    }


    /// send a command to Tello and handle the response asynchronously
    ///
    /// The handler is dispatched to a global cocurrent queue with QoS: .userInteractive.
    /// Therefore you should avoid blocking the global queue
    /// - Parameters:
    ///   - cmd: String
    ///   - remoteAddr: String
    ///   - remotePort: Int
    ///   - successHandler: ((String?) -> Void)?
    ///   - failureHandler: ((Error) -> Void)?
    func asyncSendCommand(cmd: String, remoteAddr: String, remotePort: Int, successHandler: ((String?) -> Void)?, failureHandler: ((Error) -> Void)? ) {
        do {
            let future = try dispatchCommand(cmd: cmd, remoteAddr: remoteAddr, remotePort: remotePort)
            
            future.whenSuccess { cmdResponse in
                let data = cmdResponse.data
                let dataStr = data.getString(at: 0, length: data.readableBytes)
                
                // avoid the handler being called on the same event loop
                // for example, if nesting a sync command in an async command,
                // future.wait().data will lead to deadlock if we don't use another queue
                DispatchQueue.global(qos: .userInteractive).async {
                    successHandler?(dataStr)
                }
            }

            future.whenFailure { error in
                // avoid the handler being called on the same event loop
                DispatchQueue.global(qos: .userInteractive).async {
                    failureHandler?(error)
                }
            }
            
        } catch {
            print("[TELLO]-ASYNC CMD- encounter error:", error)
            DispatchQueue.global(qos: .userInteractive).async {
                failureHandler?(error)
            }
        }
    }
    
    func telloSyncCommand(cmd: String) -> String {
        return try! syncSendCommand(cmd: cmd, remoteAddr: telloAddress, remotePort: telloPort)
    }
    
    func telloAsyncCommand(cmd: String, successHandler: ((String?) -> Void)?, failureHandler: ((Error) -> Void)? ) {
        asyncSendCommand(cmd: cmd, remoteAddr: telloAddress, remotePort: telloPort, successHandler: successHandler, failureHandler: failureHandler)
    }
}
