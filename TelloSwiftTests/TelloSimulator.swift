//
//  TelloSimulator.swift
//  TelloSwiftTests
//
//  Created by Xuan Liu on 2019/11/27.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//

import Foundation
import NIO

class TestTelloCommandHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundOut = AddressedEnvelope<ByteBuffer>

    var cmdResponse = "ok"
    var failoverResponse = "ok"

    convenience init(default response: String) {
        self.init()
        cmdResponse = response
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // As we are not really interested getting notified on success or failure,
        // we just pass nil as promise to reduce allocations.
        var buffer = unwrapInboundIn(data)
        let cmd = buffer.data.readString(length: buffer.data.readableBytes)
        var response = ""
        switch cmd {
        case "speed?":
            response = "100.0"
        case "height?":
            response = "15dm"
        case "time?":
            response = "6s"
        case "temp?":
            response = "16~86C"
        case "battery?":
            response = "66"
        case "attitude?":
            response = "pitch:0;roll:-1;yaw:0;"
        case "acceleration?":
            response = "agx:-5.00;agy:7.00;agz:-999.00;"
        case "baro?":
            response = "-106.865509"
        case "tof?":
            response = "655mm"
        case "wifi?":
            response = "90"
        case "stop":
            response = failoverResponse
        case "land":
            response = failoverResponse
        case "emergency":
            response = failoverResponse

        default:
            response = cmdResponse
        }

        let addr = buffer.remoteAddress
        // Set the transmission data.
        var responseBuffer = context.channel.allocator.buffer(capacity: response.utf8.count)
        responseBuffer.writeString(response)
        let envelope = AddressedEnvelope(remoteAddress: addr, data: responseBuffer)
        context.write(wrapOutboundOut(envelope), promise: nil)
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

class TelloSimulator {
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
                channel.pipeline.addHandler(TestTelloCommandHandler())
            })
    }

    deinit {
        if let active = channel?.isActive, active {
            channel?.close(mode: .all, promise: nil)
        }
    }

    var cmdResponse: String {
        get {
            let handler = try! channel!.pipeline.handler(type: TestTelloCommandHandler.self).wait()
            return handler.cmdResponse

        }
        set {
            let handler = try! channel!.pipeline.handler(type: TestTelloCommandHandler.self).wait()
            handler.cmdResponse = newValue
        }
    }

    var failoverResponse: String {
        get {
            let handler = try! channel!.pipeline.handler(type: TestTelloCommandHandler.self).wait()
            return handler.failoverResponse

        }
        set {
            let handler = try! channel!.pipeline.handler(type: TestTelloCommandHandler.self).wait()
            handler.failoverResponse = newValue
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
