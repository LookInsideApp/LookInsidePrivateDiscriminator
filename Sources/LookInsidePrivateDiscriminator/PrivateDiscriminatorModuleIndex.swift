import Foundation

public enum PrivateDiscriminatorModuleIndexError: Error, Equatable, CustomStringConvertible, Sendable {
    case invalidModuleName(String)

    public var description: String {
        switch self {
        case let .invalidModuleName(moduleName):
            return "Invalid module name '\(moduleName)'."
        }
    }
}

public struct PrivateDiscriminatorModuleIndex: Sendable {
    public let moduleName: String
    public let records: [PrivateDiscriminatorRecord]
    public let recordsByID: [String: PrivateDiscriminatorRecord]
    public let recordsByFilename: [String: PrivateDiscriminatorRecord]

    public init(moduleName: String, records: [PrivateDiscriminatorRecord]) throws {
        guard Self.isValidModuleName(moduleName) else {
            throw PrivateDiscriminatorModuleIndexError.invalidModuleName(moduleName)
        }
        try PrivateDiscriminatorCSV.validate(records)
        self.moduleName = moduleName
        self.records = PrivateDiscriminatorCSV.stableSorted(records)
        recordsByID = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        recordsByFilename = Dictionary(uniqueKeysWithValues: records.map { ($0.filename, $0) })
    }

    public static func read(moduleName: String, csvText: String) throws -> PrivateDiscriminatorModuleIndex {
        try PrivateDiscriminatorModuleIndex(
            moduleName: moduleName,
            records: PrivateDiscriminatorCSV.read(csvText)
        )
    }

    public func record(forID id: String) -> PrivateDiscriminatorRecord? {
        recordsByID[id.uppercased()]
    }

    public func record(forFilename filename: String) -> PrivateDiscriminatorRecord? {
        recordsByFilename[filename]
    }

    public static func isValidModuleName(_ value: String) -> Bool {
        guard !value.isEmpty, value != ".", value != ".." else {
            return false
        }
        return !value.contains("/") && !value.contains("\\")
    }
}
