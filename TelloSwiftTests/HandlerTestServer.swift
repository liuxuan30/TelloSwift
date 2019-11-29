//
//  HandlerTestServer.swift
//  TelloSwiftTests
//
//  Created by Xuan Liu on 2019/11/20.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//

import Foundation
import NIO

class UDPTestHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundOut = AddressedEnvelope<ByteBuffer>

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // As we are not really interested getting notified on success or failure,
        // we just pass nil as promise to reduce allocations.
        context.write(data, promise: nil)
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        // As we are not really interested getting notified on success or failure
        // we just pass nil as promise to reduce allocations.
        context.flush()
        
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("HandlerTestServer catches error:\(error), will shutdown")
        context.close(promise: nil)
    }
}

class HandlerTestServer {
    let eventGroup: MultiThreadedEventLoopGroup
    let bootstrap: DatagramBootstrap
    var channel: Channel?
    let addr: String
    let port: Int
    init(addr: String, port: Int) {
        self.addr = addr
        self.port = port
        eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        bootstrap = DatagramBootstrap(group: eventGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer({ channel in
                channel.pipeline.addHandler(UDPTestHandler())
            })
    }

    deinit {
        if let active = channel?.isActive, active {
            channel?.close(mode: .all, promise: nil)
        }
    }

    func start() throws {
        do {
            channel = try bootstrap.bind(host: addr, port: port).wait()
        } catch {
            print("Starting HandlerTestServer error: \(error).")
            throw error
        }
    }

    func stop() {
        channel!.close(mode: .all, promise: nil)
        try! eventGroup.syncShutdownGracefully()
    }
}
