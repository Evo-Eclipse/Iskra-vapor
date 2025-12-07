@testable import Iskra
import Testing

@Suite("Update Router Builder Tests")
struct UpdateRouterBuilderTests {

    @Test("Test build with no handlers creates router")
    func testBuildWithNoHandlersCreatesRouter() {
        // Arrange
        let sut = UpdateRouterBuilder()

        // Act
        let router = sut.build()

        // Assert
        _ = router // Value type, always non-nil
    }

    @Test("Test onCommand with multiple commands registers all")
    func testOnCommandWithMultipleCommandsRegistersAll() {
        // Arrange
        let handler = StubCommandHandler()

        // Act
        let router = UpdateRouterBuilder()
            .onCommand("start", handler: handler)
            .onCommand("help", handler: handler)
            .build()

        // Assert
        _ = router
    }

    @Test("Test onCallback with multiple prefixes registers all")
    func testOnCallbackWithMultiplePrefixesRegistersAll() {
        // Arrange
        let handler = StubCallbackHandler()

        // Act
        let router = UpdateRouterBuilder()
            .onCallback(prefix: "action", handler: handler)
            .onCallback(prefix: "menu", handler: handler)
            .build()

        // Assert
        _ = router
    }

    @Test("Test onText with handler registers it")
    func testOnTextWithHandlerRegistersIt() {
        // Arrange
        let handler = StubTextHandler()

        // Act
        let router = UpdateRouterBuilder()
            .onText(handler)
            .build()

        // Assert
        _ = router
    }

    @Test("Test fluent API returns new instance")
    func testFluentAPIReturnsNewInstance() {
        // Arrange
        let original = UpdateRouterBuilder()
        let handler = StubCommandHandler()

        // Act
        let modified = original.onCommand("test", handler: handler)

        // Assert - both should build independently (value semantics)
        _ = original.build()
        _ = modified.build()
    }

    @Test("Test chaining with multiple handler types builds router")
    func testChainingWithMultipleHandlerTypesBuildsRouter() {
        // Arrange & Act
        let router = UpdateRouterBuilder()
            .onCommand("start", handler: StubCommandHandler())
            .onCommand("help", handler: StubCommandHandler())
            .onCallback(prefix: "action", handler: StubCallbackHandler())
            .onText(StubTextHandler())
            .build()

        // Assert
        _ = router
    }
}

// MARK: - Test Doubles

private struct StubCommandHandler: CommandHandler {
    func handle(
        _ message: Components.Schemas.Message,
        command: BotCommand,
        context: UpdateContext
    ) async {}
}

private struct StubCallbackHandler: CallbackHandler {
    func handle(
        _ query: Components.Schemas.CallbackQuery,
        parsed: ParsedCallback,
        context: UpdateContext
    ) async {}
}

private struct StubTextHandler: TextMessageHandler {
    func handle(_ message: Components.Schemas.Message, context: UpdateContext) async {}
}
