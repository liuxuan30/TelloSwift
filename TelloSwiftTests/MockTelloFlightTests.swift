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

    func testValidateSpeed() {
        let speedTestsWithRange = ["speed": [9, 10, 11, 19, 20, 21, 50, 59, 60, 61, 99, 100, 101],
                                   "speedRange": [10...100],
                                   "expect": [false, true,  true,  true, true, true, true, true, true, true, true, true, false],
            ] as [String : [Any]]

        let speedTestDefault = ["speed": [9, 10, 11, 19, 20, 21, 50, 59, 60, 61, 99, 100, 101],
                                "expect": [false, true,  true,  true, true, true, true, true, true, false, false, false, false],
            ] as [String : [Any]]

        XCTAssertEqual(speedTestsWithRange["speed"]?.count, speedTestsWithRange["expect"]?.count)
        var speeds = speedTestsWithRange["speed"]!
        var expects = speedTestsWithRange["expect"]!
        for i in 0..<speeds.count {
            let r = validate(speed: (speeds[i] as! Int), distances: nil, speedRange: 10...100)
            XCTAssertEqual(r, expects[i] as! Bool)
        }

        XCTAssertEqual(speedTestDefault["speed"]?.count, speedTestDefault["expect"]?.count)
        speeds = speedTestDefault["speed"]!
        expects = speedTestDefault["expect"]!
        for i in 0..<speeds.count {
            let r = validate(speed: (speeds[i] as! Int), distances: nil)
            XCTAssertEqual(r, expects[i] as! Bool)
        }
    }

    func testValidateDistance() {
        let distances = ["distance": [(-501, -501, -501), (-500, -501, -501), (-501, -500, -500), (-500, -500, -501), (-500, -500, -500), (0, 0, 0), (19, 19, 19), (19, 20, 19), (20, 20, 20), (20, 20, 21), (20, 21, 21), (21, 21, 21), (0, -20, 100), (499, 500, 500), (500, 500, 500), (500, 500, 501), (501, 501, 501), (-500, 0, 500), (-500, 0, 501)],
                         "expect": [false, false, false, false, true, false, false, false, false, true, true, true, true, true, true, false, false, true, false]
        ] as [String : [Any]]

        XCTAssertEqual(distances["distance"]?.count, distances["expect"]?.count)
        let dists = distances["distance"]!
        let expects = distances["expect"]!
        for i in 0..<dists.count {
            let (x, y, z) = dists[i] as! (Int, Int, Int)
            let r = validate(speed: nil, distances: [x, y, z])
            XCTAssertEqual(r, expects[i] as! Bool)
        }
    }

    func testValidateNilEmpty() {
        XCTAssertFalse(validate(speed: nil, distances: nil))
        XCTAssertFalse(validate(speed: nil, distances: []))
        XCTAssertFalse(validate(speed: 9, distances: []))
        XCTAssertTrue(validate(speed: 20, distances: []))
        XCTAssertFalse(validate(speed: nil, distances: [10, 10, 10]))
        XCTAssertTrue(validate(speed: nil, distances: [10, 10, 21]))
        XCTAssertFalse(validate(speed: nil, distances: [10]))
        XCTAssertTrue(validate(speed: nil, distances: [21]))
        XCTAssertFalse(validate(speed: nil, distances: [20, 20]))
        XCTAssertTrue(validate(speed: nil, distances: [20, 21]))
        XCTAssertFalse(validate(speed: nil, distances: [-501]))
        XCTAssertTrue(validate(speed: nil, distances: [-500]))
        XCTAssertFalse(validate(speed: nil, distances: [501]))
        XCTAssertTrue(validate(speed: nil, distances: [500]))
        XCTAssertFalse(validate(speed: nil, distances: [-501, 0]))
        XCTAssertTrue(validate(speed: nil, distances: [0, -500]))
        XCTAssertFalse(validate(speed: nil, distances: [0, 501]))
        XCTAssertTrue(validate(speed: nil, distances: [500, 0]))
        XCTAssertFalse(validate(speed: nil, distances: [501, 501]))
    }

    func testValidateCombined() {
        XCTAssertFalse(validate(speed: 9, distances: [-20, -20, -20]))
        XCTAssertFalse(validate(speed: 10, distances: [10, -20, 10]))
        XCTAssertTrue(validate(speed: 60, distances: [10, 10, -21]))
        XCTAssertTrue(validate(speed: 9, distances: [10, 10, 21], speedRange: 9...60))
        XCTAssertFalse(validate(speed: 10, distances: [10]))
        XCTAssertTrue(validate(speed: 60, distances: [21]))
        XCTAssertFalse(validate(speed: 30, distances: [-20, 20]))
        XCTAssertTrue(validate(speed: 9, distances: [-20, -21]))
        XCTAssertTrue(validate(speed: 60, distances: [20, 21]))
        XCTAssertTrue(validate(speed: 60, distances: [-500, 0]))
        XCTAssertFalse(validate(speed: 20, distances: [-501]))
        XCTAssertTrue(validate(speed: 100, distances: [-500], speedRange: 10...100))
        XCTAssertFalse(validate(speed: 10, distances: [501]))
        XCTAssertTrue(validate(speed: 10, distances: [500]))
        XCTAssertFalse(validate(speed: 9, distances: [-501, 0]))
        XCTAssertTrue(validate(speed: 60, distances: [0, -500]))
        XCTAssertFalse(validate(speed: 9, distances: [0, 501]))
        XCTAssertTrue(validate(speed: 20, distances: [500, 0]))
        XCTAssertFalse(validate(speed: 20, distances: [501, 501]))
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
    
    func testTakeoff() {
        XCTAssertTrue(tello.takeoff())
        XCTAssertTrue(tello.takeoffAnd(do: "stop"))
        simulator.cmdResponse = "error"
        XCTAssertFalse(tello.takeoff())
        XCTAssertFalse(tello.takeoffAnd(do: "stop"))
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
