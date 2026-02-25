import XCTest
@testable import Take_a_Break

final class BreakManagerTests: XCTestCase {

    private var sut: BreakManager!

    override func setUp() {
        super.setUp()
        sut = BreakManager()
        // Use short intervals for testing
        sut.eyeBreakInterval = 5
        sut.eyeBreakDuration = 2
        sut.stretchBreakInterval = 10
        sut.stretchBreakDuration = 3
    }

    override func tearDown() {
        sut.pause()
        // Clean up UserDefaults test values
        for key in ["eyeBreakInterval", "eyeBreakDuration",
                     "stretchBreakInterval", "stretchBreakDuration",
                     "eyeBreakEnabled", "stretchBreakEnabled"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertFalse(sut.isRunning)
        XCTAssertFalse(sut.isOnBreak)
        XCTAssertEqual(sut.eyeBreakElapsed, 0)
        XCTAssertEqual(sut.stretchBreakElapsed, 0)
        XCTAssertEqual(sut.countdownRemaining, 0)
    }

    // MARK: - Start / Pause

    func testStartSetsRunning() {
        sut.start()
        XCTAssertTrue(sut.isRunning)
        XCTAssertEqual(sut.eyeBreakElapsed, 0)
        XCTAssertEqual(sut.stretchBreakElapsed, 0)
    }

    func testPauseStopsRunning() {
        sut.start()
        sut.pause()
        XCTAssertFalse(sut.isRunning)
    }

    // MARK: - Tick Logic

    func testTickIncrementsElapsedTimers() {
        sut.start()
        sut.tick()
        XCTAssertEqual(sut.eyeBreakElapsed, 1)
        XCTAssertEqual(sut.stretchBreakElapsed, 1)
    }

    func testTickDoesNothingWhenPaused() {
        sut.start()
        sut.pause()
        sut.tick()
        XCTAssertEqual(sut.eyeBreakElapsed, 0)
    }

    func testTickDoesNothingDuringBreak() {
        sut.start()
        sut.triggerBreak(.eye)
        let elapsed = sut.eyeBreakElapsed
        sut.tick()
        XCTAssertEqual(sut.eyeBreakElapsed, elapsed)
    }

    func testEyeBreakTriggeredAfterInterval() {
        sut.start()
        // Simulate ticks up to the eye break interval
        for _ in 0..<5 {
            sut.tick()
        }
        XCTAssertTrue(sut.isOnBreak)
        XCTAssertEqual(sut.currentBreakType, .eye)
    }

    func testStretchBreakPrioritizedOverEye() {
        // Set intervals so both trigger at the same time
        sut.eyeBreakInterval = 10
        sut.stretchBreakInterval = 10
        sut.start()
        for _ in 0..<10 {
            sut.tick()
        }
        XCTAssertTrue(sut.isOnBreak)
        XCTAssertEqual(sut.currentBreakType, .stretch,
                       "Stretch break should have higher priority when both are due")
    }

    // MARK: - Break Trigger

    func testTriggerBreakSetsCorrectState() {
        sut.start()
        sut.triggerBreak(.eye)
        XCTAssertTrue(sut.isOnBreak)
        XCTAssertEqual(sut.currentBreakType, .eye)
        XCTAssertEqual(sut.countdownRemaining, sut.eyeBreakDuration)
    }

    func testTriggerStretchBreakSetsCorrectDuration() {
        sut.start()
        sut.triggerBreak(.stretch)
        XCTAssertTrue(sut.isOnBreak)
        XCTAssertEqual(sut.currentBreakType, .stretch)
        XCTAssertEqual(sut.countdownRemaining, sut.stretchBreakDuration)
    }

    // MARK: - Skip / End Break

    func testSkipBreakEndsBreak() {
        sut.start()
        sut.triggerBreak(.eye)
        XCTAssertTrue(sut.isOnBreak)
        sut.skipBreak()
        XCTAssertFalse(sut.isOnBreak)
    }

    func testEndBreakResetsEyeElapsed() {
        sut.start()
        sut.eyeBreakElapsed = 100
        sut.triggerBreak(.eye)
        sut.endBreak()
        XCTAssertEqual(sut.eyeBreakElapsed, 0)
    }

    func testEndStretchBreakResetsBothTimers() {
        sut.start()
        sut.eyeBreakElapsed = 100
        sut.stretchBreakElapsed = 200
        sut.triggerBreak(.stretch)
        sut.endBreak()
        XCTAssertEqual(sut.eyeBreakElapsed, 0, "Eye timer should also reset after stretch break")
        XCTAssertEqual(sut.stretchBreakElapsed, 0)
    }

    // MARK: - Disabled Breaks

    func testDisabledEyeBreakDoesNotTrigger() {
        sut.eyeBreakEnabled = false
        sut.start()
        for _ in 0..<10 {
            sut.tick()
        }
        // Only stretch should trigger, not eye at tick 5
        if sut.isOnBreak {
            XCTAssertEqual(sut.currentBreakType, .stretch)
        }
    }

    func testDisabledStretchBreakDoesNotTrigger() {
        sut.stretchBreakEnabled = false
        sut.start()
        for _ in 0..<5 {
            sut.tick()
        }
        XCTAssertTrue(sut.isOnBreak)
        XCTAssertEqual(sut.currentBreakType, .eye)
    }

    // MARK: - Display Formatting

    func testFormatTimeMinutesAndSeconds() {
        XCTAssertEqual(sut.formatTime(0), "0:00")
        XCTAssertEqual(sut.formatTime(5), "0:05")
        XCTAssertEqual(sut.formatTime(60), "1:00")
        XCTAssertEqual(sut.formatTime(125), "2:05")
        XCTAssertEqual(sut.formatTime(300), "5:00")
    }

    func testCountdownTextShowsCeiledSeconds() {
        sut.start()
        sut.triggerBreak(.eye)
        sut.countdownRemaining = 5.3
        XCTAssertEqual(sut.countdownText, "0:06")
        sut.countdownRemaining = 5.0
        XCTAssertEqual(sut.countdownText, "0:05")
    }

    // MARK: - Progress Ring

    func testCountdownProgressFullAtStart() {
        sut.start()
        sut.triggerBreak(.eye)
        // countdownRemaining == eyeBreakDuration == 2.0
        let progress = sut.countdownProgress
        XCTAssertEqual(progress, 1.0, accuracy: 0.01)
    }

    func testCountdownProgressZeroWhenDone() {
        sut.start()
        sut.triggerBreak(.eye)
        sut.countdownRemaining = 0
        let progress = sut.countdownProgress
        XCTAssertEqual(progress, 0.0, accuracy: 0.01)
    }

    func testCountdownProgressMidway() {
        sut.eyeBreakDuration = 20
        sut.start()
        sut.triggerBreak(.eye)
        sut.countdownRemaining = 10.0  // Exactly halfway
        let progress = sut.countdownProgress
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    // MARK: - Time Until Next Break Strings

    func testTimeUntilNextEyeBreak() {
        sut.eyeBreakInterval = 120  // 2 minutes
        sut.eyeBreakElapsed = 0
        XCTAssertEqual(sut.timeUntilNextEyeBreak, "2:00")
    }

    func testTimeUntilNextStretchBreak() {
        sut.stretchBreakInterval = 3600  // 60 minutes
        sut.stretchBreakElapsed = 60     // 1 minute elapsed
        XCTAssertEqual(sut.timeUntilNextStretchBreak, "59:00")
    }
}
