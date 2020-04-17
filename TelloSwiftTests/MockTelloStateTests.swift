//
//  MockTelloStateTests.swift
//  TelloSwiftTests
//
//  Created by Xuan Liu on 2019/11/27.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//

import XCTest
@testable import TelloSwift

/// Tests started with Mock is using local UDP server,
/// while tests with Tello is against real Tello drone.
class MockTelloStateTests: XCTestCase {
    var telloServer: TelloSimulator!
    var tello: Tello!

    override func setUp() {
        tello = Tello()

        // mock address
        tello.telloAddress = "127.0.0.1"

        // mock as Tello
        telloServer = TelloSimulator(addr: "127.0.0.1", port: 8889)
        XCTAssertNoThrow(try telloServer!.start())
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        // cleanup the socket and event loop resources, if not called, UT would fail
        tello.cleanup()
        telloServer.stop()
        
        weak var tmpGroup = tello.group
        tello = nil
        telloServer = nil
        XCTAssertNil(tmpGroup) // check if tello has called deinit
    }

    func testGetSpeed() {
        XCTAssertEqual(tello.speed, 100)
    }
    
    func testSetSpeed() {
        tello.speed = 20
        XCTAssertFalse(tello.setSpeed(to: -10))
        XCTAssertFalse(tello.setSpeed(to: 0))
        XCTAssertFalse(tello.setSpeed(to: 9))
        XCTAssertTrue(tello.setSpeed(to: 10))
        XCTAssertTrue(tello.setSpeed(to: 50))
        XCTAssertTrue(tello.setSpeed(to: 100))
        XCTAssertFalse(tello.setSpeed(to: 101))
    }

    func testHeight() {
        XCTAssertEqual(tello.height, 150)
    }

    func testTime() {
        XCTAssertEqual(tello.time, 6)
    }

    func testTemperature() {
        XCTAssertEqual(tello.temperature, "16~86C")
    }

    func testMinTemperature() {
        XCTAssertEqual(tello.minTemp, 16)
        XCTAssertNotEqual(tello.minTemp, 15.99)
        XCTAssertNotEqual(tello.minTemp, 16.01)
    }

    func testMaxTemperature() {
        XCTAssertEqual(tello.maxTemp, 86)
        XCTAssertNotEqual(tello.maxTemp, 86.01)
        XCTAssertNotEqual(tello.maxTemp, 85.99)
    }

    func testBattery() {
        XCTAssertEqual(tello.battery, 66)
    }

    func testAttitude() {
        XCTAssertEqual(tello.attitude, "pitch:0;roll:-1;yaw:0;")
    }

    func testAcceleration() {
        XCTAssertEqual(tello.acceleration, "agx:-5.00;agy:7.00;agz:-999.00;")
    }

    func testBaro() {
        XCTAssertEqual(tello.baro, -106.865509)
        XCTAssertNotEqual(tello.baro, -106.865508)
    }

    func testTof() {
        XCTAssertEqual(tello.tof, 655)
        XCTAssertNotEqual(tello.tof, 655.001)
    }

    func testWifi() {
        XCTAssertEqual(tello.wifiSNR, 90)
    }

    func testAngAcc() {
        XCTAssertEqual(tello.agx, -5.00)
        XCTAssertEqual(tello.agy, 7.00)
        XCTAssertEqual(tello.agz, -999.00)
    }

    func testAtt() {
        XCTAssertEqual(tello.pitch, 0)
        XCTAssertEqual(tello.roll, -1)
        XCTAssertEqual(tello.yaw, 0)
    }
    
    func testEDU() {
        tello.cleanup()
        tello = nil
        var nonEDU: Tello? = Tello(EDU: false)
        XCTAssertFalse(nonEDU!.isEDU)
        nonEDU?.cleanup()
        nonEDU = nil
        tello = Tello()
        XCTAssertTrue(tello.isEDU)
    }
    
    func testSNSDK() {
        XCTAssertEqual(tello.sn, "0TQDG7REDC65P9")
        XCTAssertEqual(tello.sdkVersion, "20")
        tello._isEDU = false
        XCTAssertNil(tello.sn)
        XCTAssertNil(tello.sdkVersion)
    }
    
    func testDeinit() {
        tello.cleanup()
        var tmp: Tello? = Tello()
        weak var tmpGroup = tmp!.group
        tmp = nil
        XCTAssertNil(tmpGroup)
        XCTAssertNil(tmp)
        
        tmp = Tello()
        tmp?.keepAlive(every: 1)
        XCTAssertNotNil(tmp?.kaTimer)
        tmpGroup = tmp!.group
        tmp = nil
        XCTAssertNil(tmpGroup)
        XCTAssertNil(tmp)
        let log = """
        [TELLO-DESTROYED-]
        [TELLO-FREE-]
        [TELLO-FREE-] MUST CALL shutdown() first, trying to close the channel only, event group may escape
        [TELLO-FREE-]
        [TELLO-FREE-] Detect timer in use yet invalidated
        [TELLO-FREE-] MUST CALL shutdown() first, trying to close the channel only, event group may escape
        """
        print("=========================")
        print("You should be able to see")
        print("*************************")
        print(log)
        print("*************************")
        print("if you find the log does not match, check your code or contact dev")
        print("=========================")
    }
}
