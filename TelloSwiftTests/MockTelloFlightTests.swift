//
//  MockTelloFlightTests.swift
//  TelloSwiftTests
//
//  Created by Xuan Liu on 2019/11/28.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//

import XCTest
@testable import TelloSwift

/// Tests started with Mock is using local UDP server,
/// while tests with Tello is against real Tello drone.
class MockTelloFlightTests: XCTestCase {
    var simulator: TelloSimulator!
    var tello: Tello!

    override func setUp() {
        tello = Tello()

        // mock address
        tello.telloAddress = "127.0.0.1"

        // mock as Tello
        simulator = TelloSimulator(addr: "127.0.0.1", port: 8889)
        XCTAssertNoThrow(try simulator!.start())
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        // cleanup the socket and event loop resources, if not called, UT would fail
        tello.cleanup()
        simulator.stop()

        weak var tmpGroup = tello.group
        tello = nil
        simulator = nil
        XCTAssertNil(tmpGroup) // check if tello has called deinit
    }

    func testFlightChain() {
        let tmp = tello.chain("takeoff")?.chain("ccw 90")?.chain("cw 90")?.chain("land")
        XCTAssertNotNil(tmp)
    }

    func testFlightChainFail() {
        var tmp = tello.chain("takeoff")?.chain("ccw 90")
        XCTAssertNotNil(tmp)

        simulator.cmdResponse = "error"
        tmp = tmp?.chain("cw 90")?.chain("land")
        XCTAssertNil(tmp)
    }

    func testChainFailoverSucceed() {
        simulator.cmdResponse = "error"
        simulator.failoverResponse = "ok"
        var tmp = tello.chain("takeoff", failover: .land)?.chain("ccw 90", failover: .land)
        XCTAssertNotNil(tmp)

        simulator.cmdResponse = "ok"
        simulator.failoverResponse = "error"
        tmp = tello.chain("takeoff", failover: .land)?.chain("ccw 90", failover: .land)
        XCTAssertNotNil(tmp)
    }

    func testChainFailoverFail() {
        simulator.cmdResponse = "error"
        simulator.failoverResponse = "ok"
        var tmp = tello.chain("takeoff", failover: .emergency)?.chain("ccw 90", failover: .land)
        XCTAssertNotNil(tmp)
        simulator.failoverResponse = "error"
        tmp = tello.chain("forward 10", failover: .hover)
        XCTAssertNil(tmp)

        tmp = tello.chain("left 10", failover: nil)
        XCTAssertNil(tmp)
        tmp = tello.chain("left 10", failover: .none)
        XCTAssertNil(tmp)
    }

    func testTakeoffAndBlock() {
        let expect = XCTestExpectation()
        tello.takeoffAnd {
            expect.fulfill()
        }

        wait(for: [expect], timeout: 1)
    }

    func testLandAndBlock() {
        let expect = XCTestExpectation()
        tello.beforeLand(after: false) {
            expect.fulfill()
        }

        XCTAssertTrue(self.tello.commandChannel.isActive)

        wait(for: [expect], timeout: 1)
    }

    func testLandAndShutdown() {
        // remember shutdown() is dispatched to main queue
        let expect = XCTestExpectation()
        tello.beforeLand(after: true) {
            expect.fulfill()
        }
        
        let e2 = XCTestExpectation()
        DispatchQueue.main.async {
            XCTAssertFalse(self.tello.commandChannel.isActive)
            e2.fulfill()
        }

        wait(for: [expect, e2], timeout: 1)
    }

    func testLandAndCommand() {
        let e1 = XCTestExpectation()
        tello.beforeLand(do: "left 10", after: false)

        DispatchQueue.main.async {
            XCTAssertTrue(self.tello.commandChannel.isActive)
            e1.fulfill()
        }

        tello.beforeLand(do: "left 10", after: true)

        let e2 = XCTestExpectation()

        DispatchQueue.main.async {
            XCTAssertFalse(self.tello.commandChannel.isActive)
            e2.fulfill()
        }
        wait(for: [e1, e2], timeout: 1)
    }
}
