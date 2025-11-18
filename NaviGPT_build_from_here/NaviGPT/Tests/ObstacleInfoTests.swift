import XCTest
import CoreGraphics
@testable import NaviGPT

final class ObstacleInfoTests: XCTestCase {
    
    func testObstacleCreation() {
        let obstacle = ObstacleInfo(
            type: .person,
            distance: 1.5,
            position: .center,
            confidence: 0.95
        )
        
        XCTAssertEqual(obstacle.type, .person)
        XCTAssertEqual(obstacle.distance, 1.5, accuracy: 0.01)
        XCTAssertEqual(obstacle.position, .center)
        XCTAssertEqual(obstacle.confidence, 0.95, accuracy: 0.01)
    }
    
    // MARK: - Severity Tests
    
    func testSeverityCritical() {
        let obstacle = ObstacleInfo(type: .wall, distance: 0.3, position: .center)
        XCTAssertEqual(obstacle.severity, .critical)
    }
    
    func testSeverityUrgent() {
        let obstacle = ObstacleInfo(type: .vehicle, distance: 0.7, position: .center)
        XCTAssertEqual(obstacle.severity, .urgent)
    }
    
    func testSeverityWarning() {
        let obstacle = ObstacleInfo(type: .person, distance: 1.5, position: .center)
        XCTAssertEqual(obstacle.severity, .warning)
    }
    
    func testSeverityCaution() {
        let obstacle = ObstacleInfo(type: .pole, distance: 2.5, position: .center)
        XCTAssertEqual(obstacle.severity, .caution)
    }
    
    func testSeverityInfo() {
        let obstacle = ObstacleInfo(type: .tree, distance: 5.0, position: .center)
        XCTAssertEqual(obstacle.severity, .info)
    }
    
    // MARK: - Vibration Intensity Tests
    
    func testVibrationIntensityForCritical() {
        let obstacle = ObstacleInfo(type: .wall, distance: 0.3, position: .center)
        XCTAssertEqual(obstacle.vibrationIntensity, 1.0, accuracy: 0.01)
    }
    
    func testVibrationIntensityForInfo() {
        let obstacle = ObstacleInfo(type: .tree, distance: 5.0, position: .center)
        XCTAssertEqual(obstacle.vibrationIntensity, 0.2, accuracy: 0.01)
    }
    
    // MARK: - Vibration Interval Tests
    
    func testVibrationIntervalForCritical() {
        let obstacle = ObstacleInfo(type: .wall, distance: 0.3, position: .center)
        XCTAssertEqual(obstacle.vibrationInterval, 0.2, accuracy: 0.01)
    }
    
    func testVibrationIntervalForInfo() {
        let obstacle = ObstacleInfo(type: .tree, distance: 5.0, position: .center)
        XCTAssertEqual(obstacle.vibrationInterval, 3.0, accuracy: 0.01)
    }
    
    // MARK: - Obstacle Type Tests
    
    func testObstacleTypeDisplayNames() {
        XCTAssertEqual(ObstacleType.person.displayName, "Person")
        XCTAssertEqual(ObstacleType.vehicle.displayName, "Vehicle")
        XCTAssertEqual(ObstacleType.stairs.displayName, "Stairs")
    }
    
    func testObstacleTypeIsMoving() {
        XCTAssertTrue(ObstacleType.person.isMoving)
        XCTAssertTrue(ObstacleType.vehicle.isMoving)
        XCTAssertTrue(ObstacleType.bicycle.isMoving)
        XCTAssertFalse(ObstacleType.wall.isMoving)
        XCTAssertFalse(ObstacleType.pole.isMoving)
    }
    
    // MARK: - Obstacle Position Tests
    
    func testObstaclePositionClockPosition() {
        XCTAssertEqual(ObstaclePosition.center.clockPosition, "12 o'clock")
        XCTAssertEqual(ObstaclePosition.left.clockPosition, "10 o'clock")
        XCTAssertEqual(ObstaclePosition.right.clockPosition, "2 o'clock")
        XCTAssertEqual(ObstaclePosition.farLeft.clockPosition, "9 o'clock")
        XCTAssertEqual(ObstaclePosition.farRight.clockPosition, "3 o'clock")
    }
    
    func testObstaclePositionDescription() {
        XCTAssertEqual(ObstaclePosition.center.description, "ahead")
        XCTAssertEqual(ObstaclePosition.left.description, "on your left")
        XCTAssertEqual(ObstaclePosition.right.description, "on your right")
    }
    
    // MARK: - Obstacle Severity Comparison Tests
    
    func testSeverityComparison() {
        XCTAssertTrue(ObstacleSeverity.info < ObstacleSeverity.caution)
        XCTAssertTrue(ObstacleSeverity.caution < ObstacleSeverity.warning)
        XCTAssertTrue(ObstacleSeverity.warning < ObstacleSeverity.urgent)
        XCTAssertTrue(ObstacleSeverity.urgent < ObstacleSeverity.critical)
    }
    
    // MARK: - Equatable Tests
    
    func testObstacleEquality() {
        let id = UUID()
        let obstacle1 = ObstacleInfo(
            id: id,
            type: .person,
            distance: 1.5,
            position: .center,
            confidence: 0.95
        )
        
        let obstacle2 = ObstacleInfo(
            id: id,
            type: .person,
            distance: 1.5,
            position: .center,
            confidence: 0.95
        )
        
        XCTAssertEqual(obstacle1, obstacle2)
    }
    
    func testObstacleInequality() {
        let obstacle1 = ObstacleInfo(type: .person, distance: 1.5, position: .center)
        let obstacle2 = ObstacleInfo(type: .vehicle, distance: 2.0, position: .left)
        
        XCTAssertNotEqual(obstacle1, obstacle2)
    }
}
