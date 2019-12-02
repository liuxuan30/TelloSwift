//
//  TelloStateHandler.swift
//  TelloSwift
//
//  Created by Xuan Liu on 2019/11/26.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//  Licensed under Apache License 2.0
//

import Foundation
import NIO

public protocol TelloState: AnyObject {
    /// Obtain tello state, this is dispatched to default global queue
    /// - Parameter frame: String?
    func telloState(receive state: String)
}

class TelloStateHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    weak var delegate: TelloState?
    private var state: String = ""

    init(delegate: TelloState? = nil) {
        self.delegate = delegate
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("[TELLO-STATE-] error:", error)
        context.fireErrorCaught(error)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data).data
        state += buffer.readString(length: buffer.readableBytes) ?? ""
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        let data = state
        state = ""
        DispatchQueue.global(qos: .default).async { [weak self] in
            self?.delegate?.telloState(receive: data)
        }
    }
}
