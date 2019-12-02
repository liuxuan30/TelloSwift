//
//  TelloComandHandler.swift
//  TelloSwift
//
//  Created by Xuan Liu on 2019/11/19.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//  Licensed under Apache License 2.0
//

import Foundation
import NIO


/// A Tello duplex handler that will send out the command and return a promise of response
public class TelloCommandHandler<Request, Response>: ChannelDuplexHandler {
    public typealias InboundIn = Response
    public typealias OutboundOut = Request
    public typealias OutboundIn = (Request, EventLoopPromise<Response>)

    private enum State {
        case normal
        case error(Error)

        var isOperational: Bool {
            switch self {
            case .normal:
                return true
            case .error:
                return false
            }
        }
    }

    private var state: State = .normal
    private var promiseBuffer: CircularBuffer<EventLoopPromise<Response>> = []

    public init(initialBufferCapacity: Int = 8) {
        promiseBuffer = CircularBuffer(initialCapacity: initialBufferCapacity)
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        guard state.isOperational else {
            assert(self.promiseBuffer.count == 0)
            return
        }
        state = .error(error)
        let buffer = promiseBuffer
        promiseBuffer.removeAll()
        context.close(promise: nil)
        buffer.forEach { $0.fail(error) }
    }


    /// fulfill response promise
    /// - Parameters:
    ///   - context: ChannelHandlerContext
    ///   - data: Response inside NIOAny
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard state.isOperational else {
            // we're in an error state, ignore further responses
            assert(self.promiseBuffer.count == 0)
            return
        }

        let response = unwrapInboundIn(data)
        if (promiseBuffer.count > 0) {
            let promise = promiseBuffer.removeFirst()
            promise.succeed(response)
        } else {
            if let envelope = response as? AddressedEnvelope<ByteBuffer> {
                var buffer = envelope.data
                print("[TELLO-CMD READ-] Unfulfilled:", buffer.readString(length: buffer.readableBytes) ?? "Unreadable bytes")
            }
        }
    }


    /// The handler will store the response promise in a circular buffer and send the raw request
    /// - Parameters:
    ///   - context: ChannelHandlerContext
    ///   - data: tuple, (Request, EventLoopPromise<Response>)
    ///   - promise: EventLoopPromise<Void>?
    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let (request, responsePromise) = unwrapOutboundIn(data)
        switch state {
        case .error(let error):
            assert(promiseBuffer.count == 0)
            responsePromise.fail(error)
            promise?.fail(error)
        case .normal:
            self.promiseBuffer.append(responsePromise)
            context.write(wrapOutboundOut(request), promise: promise)
        }
    }
}
