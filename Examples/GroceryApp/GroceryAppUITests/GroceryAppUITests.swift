import XCTest

final class GroceryAppUITests: XCTestCase {

    func testNavigatingFromListToItemsShowsItems() {
        let app = XCUIApplication()
        app.launch()

        let row = app.staticTexts["Weekly groceries"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        let firstItem = app.staticTexts["Apples"]
        XCTAssertTrue(firstItem.waitForExistence(timeout: 5), "Items should appear after navigating into a list")
    }

    func testCompletedStatePersistsAfterNavigatingToItemsAndBack() {
        let app = XCUIApplication()
        app.launch()

        let toggle = app.buttons["toggle-Weekly groceries"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()
        XCTAssertEqual(toggle.label, "Completed")

        let row = app.staticTexts["Weekly groceries"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        let firstItem = app.staticTexts["Apples"]
        XCTAssertTrue(firstItem.waitForExistence(timeout: 5))

        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(toggle.label, "Completed", "Completed state should persist after navigating away and back")
    }
}
