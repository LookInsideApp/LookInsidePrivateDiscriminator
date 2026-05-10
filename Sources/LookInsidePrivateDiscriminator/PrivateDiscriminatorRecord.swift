import Foundation

public struct PrivateDiscriminatorRecord: Codable, Hashable, Sendable {
    public var id: String
    public var filename: String
    public var created_at: String
    public var updated_at: String
    public var created_by: String
    public var updated_by: String

    public init(
        id: String,
        filename: String,
        created_at: String,
        updated_at: String,
        created_by: String,
        updated_by: String
    ) {
        self.id = id
        self.filename = filename
        self.created_at = created_at
        self.updated_at = updated_at
        self.created_by = created_by
        self.updated_by = updated_by
    }
}

public extension PrivateDiscriminatorRecord {
    static let userAuthor = "user"
    static let lookInsideAIAuthor = "LookInside AI"
}
