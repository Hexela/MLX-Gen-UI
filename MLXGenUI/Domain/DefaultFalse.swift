import Foundation

/// A Boolean that decodes as `false` when older task documents omit it.
@propertyWrapper
struct DefaultFalse: Codable, Equatable, Hashable, Sendable {
    var wrappedValue = false

    init(wrappedValue: Bool = false) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(Bool.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension KeyedDecodingContainer {
    func decode(_ type: DefaultFalse.Type, forKey key: Key) throws -> DefaultFalse {
        try decodeIfPresent(type, forKey: key) ?? DefaultFalse()
    }
}
