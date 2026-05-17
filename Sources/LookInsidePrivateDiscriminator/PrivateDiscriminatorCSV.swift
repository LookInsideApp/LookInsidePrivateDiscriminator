import Foundation
import TabularData

public enum PrivateDiscriminatorCSVError: Error, Equatable, CustomStringConvertible, Sendable {
    case emptyDocument
    case invalidHeader(expected: [String], actual: [String])
    case invalidColumnCount(row: Int, expected: Int, actual: Int)
    case missingRequiredField(row: Int, field: String)
    case invalidID(row: Int, id: String)
    case invalidFilename(row: Int, filename: String)
    case invalidTimestamp(row: Int, field: String, value: String)
    case duplicateID(row: Int, id: String)
    case duplicateFilename(row: Int, filename: String)
    case unterminatedQuotedField(row: Int)

    public var description: String {
        switch self {
        case .emptyDocument:
            return "CSV document is empty."
        case let .invalidHeader(expected, actual):
            return "Invalid CSV header. Expected \(expected.joined(separator: ",")); got \(actual.joined(separator: ","))."
        case let .invalidColumnCount(row, expected, actual):
            return "Row \(row) has \(actual) columns; expected \(expected)."
        case let .missingRequiredField(row, field):
            return "Row \(row) is missing required field '\(field)'."
        case let .invalidID(row, id):
            return "Row \(row) has invalid id '\(id)'. Expected uppercase 32-character hex."
        case let .invalidFilename(row, filename):
            return "Row \(row) has invalid basename-only filename '\(filename)'."
        case let .invalidTimestamp(row, field, value):
            return "Row \(row) has invalid \(field) timestamp '\(value)'. Expected yyyy-MM-dd'T'HH:mm:ss'Z'."
        case let .duplicateID(row, id):
            return "Row \(row) duplicates id '\(id)'."
        case let .duplicateFilename(row, filename):
            return "Row \(row) duplicates filename '\(filename)'."
        case let .unterminatedQuotedField(row):
            return "Row \(row) has an unterminated quoted field."
        }
    }
}

public enum PrivateDiscriminatorCSV {
    public static let headerFields = [
        "id",
        "filename",
        "created_at",
        "updated_at",
        "created_by",
        "updated_by",
    ]

    public static func read(_ text: String) throws -> [PrivateDiscriminatorRecord] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PrivateDiscriminatorCSVError.emptyDocument
        }
        let dataFrame: DataFrame
        do {
            dataFrame = try DataFrame(csvData: Data(text.utf8), types: columnTypes)
        } catch let error as CSVReadingError {
            throw mapCSVReadingError(error)
        }

        let header = dataFrame.columns.map(\.name)
        guard header == headerFields else {
            throw PrivateDiscriminatorCSVError.invalidHeader(expected: headerFields, actual: header)
        }

        let records = try (0 ..< dataFrame.rows.count).map { rowIndex in
            let rowNumber = rowIndex + 2
            let createdAt = try timestampDate(
                from: stringValue(in: dataFrame, field: "created_at", rowIndex: rowIndex),
                row: rowNumber,
                field: "created_at"
            )
            let updatedAt = try timestampDate(
                from: stringValue(in: dataFrame, field: "updated_at", rowIndex: rowIndex),
                row: rowNumber,
                field: "updated_at"
            )
            return PrivateDiscriminatorRecord(
                id: stringValue(in: dataFrame, field: "id", rowIndex: rowIndex),
                filename: stringValue(in: dataFrame, field: "filename", rowIndex: rowIndex),
                created_at: createdAt,
                updated_at: updatedAt,
                created_by: PrivateDiscriminatorRecordAuthor(
                    rawValue: stringValue(in: dataFrame, field: "created_by", rowIndex: rowIndex)
                ),
                updated_by: PrivateDiscriminatorRecordAuthor(
                    rawValue: stringValue(in: dataFrame, field: "updated_by", rowIndex: rowIndex)
                )
            )
        }
        try validate(records)
        return records
    }

    public static func write(_ records: [PrivateDiscriminatorRecord]) throws -> String {
        try validate(records)
        var rows: [[String]] = [headerFields]
        rows.append(contentsOf: stableSorted(records).map { record in
            [
                record.id,
                record.filename,
                timestampString(from: record.created_at),
                timestampString(from: record.updated_at),
                record.created_by.rawValue,
                record.updated_by.rawValue,
            ]
        })
        return rows.map { $0.map(escapedField).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    public static func validate(_ records: [PrivateDiscriminatorRecord]) throws {
        var seenIDs: Set<String> = []
        var seenFilenames: Set<String> = []

        for (offset, record) in records.enumerated() {
            let rowNumber = offset + 2
            try validateRequired(record.id, row: rowNumber, field: "id")
            try validateRequired(record.filename, row: rowNumber, field: "filename")
            try validateRequired(record.created_by.rawValue, row: rowNumber, field: "created_by")
            try validateRequired(record.updated_by.rawValue, row: rowNumber, field: "updated_by")

            guard isValidID(record.id) else {
                throw PrivateDiscriminatorCSVError.invalidID(row: rowNumber, id: record.id)
            }
            guard isValidFilename(record.filename) else {
                throw PrivateDiscriminatorCSVError.invalidFilename(row: rowNumber, filename: record.filename)
            }
            guard seenIDs.insert(record.id).inserted else {
                throw PrivateDiscriminatorCSVError.duplicateID(row: rowNumber, id: record.id)
            }
            guard seenFilenames.insert(record.filename).inserted else {
                throw PrivateDiscriminatorCSVError.duplicateFilename(row: rowNumber, filename: record.filename)
            }
        }
    }

    public static func isValidID(_ value: String) -> Bool {
        guard value.count == 32 else {
            return false
        }
        return value.allSatisfy { character in
            ("0" ... "9").contains(character) || ("A" ... "F").contains(character)
        }
    }

    public static func isValidFilename(_ value: String) -> Bool {
        guard !value.isEmpty, value != ".", value != ".." else {
            return false
        }
        return !value.contains("/") && !value.contains("\\")
    }

    public static func isValidTimestamp(_ value: String) -> Bool {
        date(fromTimestamp: value) != nil
    }

    public static func date(fromTimestamp value: String) -> Date? {
        guard timestampPattern.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) != nil else {
            return nil
        }
        guard let date = timestampFormatter.date(from: value) else {
            return nil
        }
        return timestampFormatter.string(from: date) == value ? date : nil
    }

    public static func timestampString(from date: Date) -> String {
        timestampFormatter.string(from: date)
    }

    public static func stableSorted(_ records: [PrivateDiscriminatorRecord]) -> [PrivateDiscriminatorRecord] {
        records.sorted { lhs, rhs in
            let lhsFilename = lhs.filename.lowercased()
            let rhsFilename = rhs.filename.lowercased()
            if lhsFilename != rhsFilename {
                return lhsFilename < rhsFilename
            }
            if lhs.filename != rhs.filename {
                return lhs.filename < rhs.filename
            }
            return lhs.id < rhs.id
        }
    }

    private static func validateRequired(_ value: String, row: Int, field: String) throws {
        if value.isEmpty {
            throw PrivateDiscriminatorCSVError.missingRequiredField(row: row, field: field)
        }
    }

    private static func escapedField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    private static func stringValue(in dataFrame: DataFrame, field: String, rowIndex: Int) -> String {
        dataFrame[field][rowIndex] as? String ?? ""
    }

    private static func timestampDate(from value: String, row: Int, field: String) throws -> Date {
        try validateRequired(value, row: row, field: field)
        guard let date = date(fromTimestamp: value) else {
            throw PrivateDiscriminatorCSVError.invalidTimestamp(row: row, field: field, value: value)
        }
        return date
    }

    private static func mapCSVReadingError(_ error: CSVReadingError) -> Error {
        switch error {
        case let .wrongNumberOfColumns(row, columns, expected):
            return PrivateDiscriminatorCSVError.invalidColumnCount(
                row: row + 1,
                expected: expected,
                actual: columns
            )
        default:
            return error
        }
    }

    private static let columnTypes: [String: CSVType] = [
        "id": .string,
        "filename": .string,
        "created_at": .string,
        "updated_at": .string,
        "created_by": .string,
        "updated_by": .string,
    ]

    private static let timestampPattern = try! NSRegularExpression(
        pattern: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"#
    )

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.isLenient = false
        return formatter
    }()
}
