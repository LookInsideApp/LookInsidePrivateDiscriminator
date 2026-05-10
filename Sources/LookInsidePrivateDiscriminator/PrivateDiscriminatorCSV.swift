import Foundation

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
        let rows = try parseRows(from: text)
        guard let header = rows.first else {
            throw PrivateDiscriminatorCSVError.emptyDocument
        }
        guard header == headerFields else {
            throw PrivateDiscriminatorCSVError.invalidHeader(expected: headerFields, actual: header)
        }

        let records = try rows.dropFirst().enumerated().map { offset, row in
            let rowNumber = offset + 2
            guard row.count == headerFields.count else {
                throw PrivateDiscriminatorCSVError.invalidColumnCount(
                    row: rowNumber,
                    expected: headerFields.count,
                    actual: row.count
                )
            }
            return PrivateDiscriminatorRecord(
                id: row[0],
                filename: row[1],
                created_at: row[2],
                updated_at: row[3],
                created_by: row[4],
                updated_by: row[5]
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
                record.created_at,
                record.updated_at,
                record.created_by,
                record.updated_by,
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
            try validateRequired(record.created_at, row: rowNumber, field: "created_at")
            try validateRequired(record.updated_at, row: rowNumber, field: "updated_at")
            try validateRequired(record.created_by, row: rowNumber, field: "created_by")
            try validateRequired(record.updated_by, row: rowNumber, field: "updated_by")

            guard isValidID(record.id) else {
                throw PrivateDiscriminatorCSVError.invalidID(row: rowNumber, id: record.id)
            }
            guard isValidFilename(record.filename) else {
                throw PrivateDiscriminatorCSVError.invalidFilename(row: rowNumber, filename: record.filename)
            }
            guard isValidTimestamp(record.created_at) else {
                throw PrivateDiscriminatorCSVError.invalidTimestamp(row: rowNumber, field: "created_at", value: record.created_at)
            }
            guard isValidTimestamp(record.updated_at) else {
                throw PrivateDiscriminatorCSVError.invalidTimestamp(row: rowNumber, field: "updated_at", value: record.updated_at)
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
        guard timestampPattern.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) != nil else {
            return false
        }
        guard let date = timestampFormatter.date(from: value) else {
            return false
        }
        return timestampFormatter.string(from: date) == value
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

    private static func parseRows(from text: String) throws -> [[String]] {
        var workingText = text
        if workingText.hasPrefix("\u{feff}") {
            workingText.removeFirst()
        }
        guard !workingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PrivateDiscriminatorCSVError.emptyDocument
        }

        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isInsideQuotes = false
        var currentRowNumber = 1
        var index = workingText.startIndex

        while index < workingText.endIndex {
            let character = workingText[index]
            let next = workingText.index(after: index)

            if isInsideQuotes {
                if character == "\"" {
                    if next < workingText.endIndex, workingText[next] == "\"" {
                        field.append("\"")
                        index = workingText.index(after: next)
                    } else {
                        isInsideQuotes = false
                        index = next
                    }
                } else {
                    if character == "\n" {
                        currentRowNumber += 1
                    }
                    field.append(character)
                    index = next
                }
                continue
            }

            switch character {
            case "\"":
                if field.isEmpty {
                    isInsideQuotes = true
                } else {
                    field.append(character)
                }
                index = next
            case ",":
                row.append(field)
                field.removeAll(keepingCapacity: true)
                index = next
            case "\n":
                row.append(field)
                appendRow(row, to: &rows)
                row.removeAll(keepingCapacity: true)
                field.removeAll(keepingCapacity: true)
                currentRowNumber += 1
                index = next
            case "\r":
                row.append(field)
                appendRow(row, to: &rows)
                row.removeAll(keepingCapacity: true)
                field.removeAll(keepingCapacity: true)
                if next < workingText.endIndex, workingText[next] == "\n" {
                    index = workingText.index(after: next)
                } else {
                    index = next
                }
                currentRowNumber += 1
            default:
                field.append(character)
                index = next
            }
        }

        if isInsideQuotes {
            throw PrivateDiscriminatorCSVError.unterminatedQuotedField(row: currentRowNumber)
        }
        row.append(field)
        appendRow(row, to: &rows)
        return rows
    }

    private static func appendRow(_ row: [String], to rows: inout [[String]]) {
        if row.count == 1, row[0].isEmpty, !rows.isEmpty {
            return
        }
        rows.append(row)
    }

    private static func escapedField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    private static let timestampPattern = try! NSRegularExpression(
        pattern: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"#
    )

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()
}
