import Foundation

public struct PrivateDiscriminatorRecordAuthor: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        rawValue = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var description: String {
        rawValue
    }

    public static let user: Self = "user"
    public static let imported: Self = "imported"
}

public struct PrivateDiscriminatorRecord: Codable, Hashable, Sendable {
    public var id: String
    public var filename: String
    public var created_at: Date
    public var updated_at: Date
    public var created_by: PrivateDiscriminatorRecordAuthor
    public var updated_by: PrivateDiscriminatorRecordAuthor

    public init(
        id: String,
        filename: String,
        created_at: Date,
        updated_at: Date,
        created_by: PrivateDiscriminatorRecordAuthor,
        updated_by: PrivateDiscriminatorRecordAuthor
    ) {
        self.id = id
        self.filename = filename
        self.created_at = created_at
        self.updated_at = updated_at
        self.created_by = created_by
        self.updated_by = updated_by
    }
}
