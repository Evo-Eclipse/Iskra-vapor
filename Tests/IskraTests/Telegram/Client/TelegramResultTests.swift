@testable import Iskra
import Logging
import Testing

@Suite("Telegram Result Tests")
struct TelegramResultTests {

    @Test("Test value returns wrapped value")
    func testValueWithSuccessReturnsWrappedValue() {
        // Arrange
        let sut: TelegramResult<Int> = .success(42)

        // Act
        let result = sut.value

        // Assert
        #expect(result == 42)
    }

    @Test("Test value returns nil for failure")
    func testValueWithFailureReturnsNil() {
        // Arrange
        let sut: TelegramResult<Int> = .failure(.authenticationFailed)

        // Act
        let result = sut.value

        // Assert
        #expect(result == nil)
    }

    @Test("Test isSuccess returns true for success")
    func testIsSuccessWithSuccessReturnsTrue() {
        // Arrange
        let sut: TelegramResult<Int> = .success(1)

        // Act
        let result = sut.isSuccess

        // Assert
        #expect(result == true)
    }

    @Test("Test isSuccess returns false for failure")
    func testIsSuccessWithFailureReturnsFalse() {
        // Arrange
        let sut: TelegramResult<Int> = .failure(.authenticationFailed)

        // Act
        let result = sut.isSuccess

        // Assert
        #expect(result == false)
    }

    @Test("Test get returns value for success")
    func testGetWithSuccessReturnsValue() throws {
        // Arrange
        let sut: TelegramResult<String> = .success("hello")

        // Act
        let result = try sut.get()

        // Assert
        #expect(result == "hello")
    }

    @Test("Test get throws error for failure")
    func testGetWithFailureThrows() {
        // Arrange
        let sut: TelegramResult<String> = .failure(.authenticationFailed)

        // Act & Assert
        #expect(throws: TelegramError.self) {
            try sut.get()
        }
    }

    @Test("Test map transforms value while preserving success")
    func testMapWithSuccessTransformsValue() {
        // Arrange
        let sut: TelegramResult<Int> = .success(5)

        // Act
        let result = sut.map { $0 * 2 }

        // Assert
        #expect(result.value == 10)
    }

    @Test("Test map preserves error state for failure")
    func testMapWithFailurePreservesError() {
        // Arrange
        let sut: TelegramResult<Int> = .failure(.authenticationFailed)

        // Act
        let result = sut.map { $0 * 2 }

        // Assert
        #expect(result.isSuccess == false)
    }

    @Test("Test flatMap chains transformations successfully")
    func testFlatMapWithSuccessChainsTransform() {
        // Arrange
        let sut: TelegramResult<Int> = .success(5)

        // Act
        let result = sut.flatMap { .success($0 * 2) }

        // Assert
        #expect(result.value == 10)
    }

    @Test("Test flatMap short-circuits for failure")
    func testFlatMapWithFailureShortCircuits() {
        // Arrange
        let sut: TelegramResult<Int> = .failure(.authenticationFailed)

        // Act
        let result = sut.flatMap { .success($0 * 2) }

        // Assert
        #expect(result.isSuccess == false)
    }

    @Test("Test flatMap propagates failure when transformation fails")
    func testFlatMapWithSuccessReturningFailurePropagatesFailure() {
        // Arrange
        let sut: TelegramResult<Int> = .success(5)

        // Act
        let result: TelegramResult<Int> = sut.flatMap { _ in .failure(.authenticationFailed) }

        // Assert
        #expect(result.isSuccess == false)
    }
}
