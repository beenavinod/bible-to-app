//
//  BIBLE_TODOUITests.swift
//  BIBLE TODOUITests
//
//  Created by Beena Vinod on 04/04/26.
//

import XCTest

final class BIBLE_TODOUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["TODAY'S ACTION"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Press and hold to complete"].waitForExistence(timeout: 2))

        app.buttons["Journey"].tap()
        XCTAssertTrue(app.staticTexts["ACHIEVEMENT ICONS"].waitForExistence(timeout: 2))

        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Themes"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
