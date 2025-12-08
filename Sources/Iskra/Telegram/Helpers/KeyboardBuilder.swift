import Foundation

/// Helper for building Telegram keyboards with a fluent API.
/// Supports both Inline and Reply keyboards.
struct KeyboardBuilder: Sendable {
    // MARK: - State

    private var inlineRows: [[Components.Schemas.InlineKeyboardButton]] = []
    private var currentInlineRow: [Components.Schemas.InlineKeyboardButton] = []

    private var replyRows: [[Components.Schemas.KeyboardButton]] = []
    private var currentReplyRow: [Components.Schemas.KeyboardButton] = []

    private let type: KeyboardType

    enum KeyboardType {
        case inline
        case reply
    }

    // MARK: - Init

    init(type: KeyboardType) {
        self.type = type
    }

    // MARK: - Inline Buttons

    /// Adds a button to the current row (Inline).
    @discardableResult
    mutating func button(text: String, callbackData: String) -> KeyboardBuilder {
        guard type == .inline else { return self }
        currentInlineRow.append(.init(text: text, callback_data: callbackData))
        return self
    }

    /// Adds a button with a URL (Inline).
    @discardableResult
    mutating func urlButton(text: String, url: String) -> KeyboardBuilder {
        guard type == .inline else { return self }
        currentInlineRow.append(.init(text: text, url: url))
        return self
    }

    // MARK: - Reply Buttons

    /// Adds a text button (Reply).
    @discardableResult
    mutating func button(text: String) -> KeyboardBuilder {
        guard type == .reply else { return self }
        currentReplyRow.append(.init(text: text))
        return self
    }

    /// Adds a "Request Contact" button (Reply).
    @discardableResult
    mutating func requestContact(text: String) -> KeyboardBuilder {
        guard type == .reply else { return self }
        currentReplyRow.append(.init(text: text, request_contact: true))
        return self
    }

    /// Adds a "Request Location" button (Reply).
    @discardableResult
    mutating func requestLocation(text: String) -> KeyboardBuilder {
        guard type == .reply else { return self }
        currentReplyRow.append(.init(text: text, request_location: true))
        return self
    }

    // MARK: - Layout Control

    /// Completes the current row and starts a new one.
    @discardableResult
    mutating func row() -> KeyboardBuilder {
        if type == .inline {
            if !currentInlineRow.isEmpty {
                inlineRows.append(currentInlineRow)
                currentInlineRow = []
            }
        } else {
            if !currentReplyRow.isEmpty {
                replyRows.append(currentReplyRow)
                currentReplyRow = []
            }
        }
        return self
    }

    // MARK: - Build

    /// Builds InlineKeyboardMarkup.
    func buildInline() -> Components.Schemas.InlineKeyboardMarkup {
        var finalRows = inlineRows
        if !currentInlineRow.isEmpty {
            finalRows.append(currentInlineRow)
        }
        return .init(inline_keyboard: finalRows)
    }

    /// Builds ReplyKeyboardMarkup.
    func buildReply(oneTime: Bool = true, resize: Bool = true) -> Components.Schemas.ReplyKeyboardMarkup {
        var finalRows = replyRows
        if !currentReplyRow.isEmpty {
            finalRows.append(currentReplyRow)
        }
        return .init(
            keyboard: finalRows,
            resize_keyboard: resize,
            one_time_keyboard: oneTime,
        )
    }
}
