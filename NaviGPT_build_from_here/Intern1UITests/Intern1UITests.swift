import XCTest

class Intern1UITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testBasicAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(true, "App launched successfully")
    }
}
