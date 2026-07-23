import Foundation

@propertyWrapper
nonisolated struct StringEncodedDecimal: Codable, Hashable, Sendable {
    let wrappedValue: Decimal

    init(wrappedValue: Decimal) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let decimal = try? container.decode(Decimal.self) {
            wrappedValue = decimal
            return
        }

        let value = try container.decode(String.self)
        guard let decimal = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a decimal encoded as a JSON number or string."
            )
        }
        wrappedValue = decimal
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(NSDecimalNumber(decimal: wrappedValue).stringValue)
    }
}
