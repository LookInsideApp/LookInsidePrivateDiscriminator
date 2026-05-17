import XCTest
@testable import LookInsidePrivateDiscriminator

final class PrivateDiscriminatorCSVTests: XCTestCase {
    func testRoundTripUsesStableHeaderOrderAndOutput() throws {
        let records = [
            record(id: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", filename: "ZooView.swift"),
            record(id: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", filename: "AppView.swift"),
        ]

        let csv = try PrivateDiscriminatorCSV.write(records)

        XCTAssertEqual(
            csv,
            """
            id,filename,created_at,updated_at,created_by,updated_by
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,AppView.swift,2026-05-10T00:00:00Z,2026-05-10T00:00:00Z,user,user
            BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB,ZooView.swift,2026-05-10T00:00:00Z,2026-05-10T00:00:00Z,user,user

            """
        )
        XCTAssertEqual(try PrivateDiscriminatorCSV.read(csv), [
            record(id: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", filename: "AppView.swift"),
            record(id: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", filename: "ZooView.swift"),
        ])
    }

    func testRequiredFieldsAreStrict() {
        let csv = """
        id,filename,created_at,updated_at,created_by,updated_by
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,,2026-05-10T00:00:00Z,2026-05-10T00:00:00Z,user,user

        """

        XCTAssertThrowsError(try PrivateDiscriminatorCSV.read(csv)) { error in
            XCTAssertEqual(error as? PrivateDiscriminatorCSVError, .missingRequiredField(row: 2, field: "filename"))
        }
    }

    func testTimestampFormatIsStrictUTCSeconds() {
        let csv = """
        id,filename,created_at,updated_at,created_by,updated_by
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,AppView.swift,2026-05-10T00:00:00.000Z,2026-05-10T00:00:00Z,user,user

        """

        XCTAssertThrowsError(try PrivateDiscriminatorCSV.read(csv)) { error in
            XCTAssertEqual(
                error as? PrivateDiscriminatorCSVError,
                .invalidTimestamp(row: 2, field: "created_at", value: "2026-05-10T00:00:00.000Z")
            )
        }
    }

    func testInvalidColumnCountIsRejected() {
        let csv = """
        id,filename,created_at,updated_at,created_by,updated_by
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,AppView.swift,2026-05-10T00:00:00Z,2026-05-10T00:00:00Z,user,user,extra

        """

        XCTAssertThrowsError(try PrivateDiscriminatorCSV.read(csv)) { error in
            XCTAssertEqual(
                error as? PrivateDiscriminatorCSVError,
                .invalidColumnCount(row: 2, expected: 6, actual: 7)
            )
        }
    }

    func testAuthorSupportsRawValueAndStringLiteral() throws {
        let custom: PrivateDiscriminatorRecordAuthor = "custom"

        XCTAssertEqual(custom.rawValue, "custom")
        XCTAssertEqual(PrivateDiscriminatorRecordAuthor.user.rawValue, "user")
        XCTAssertEqual(PrivateDiscriminatorRecordAuthor.imported.rawValue, "imported")
        let encoded = try JSONEncoder().encode(PrivateDiscriminatorRecordAuthor.imported)
        XCTAssertEqual(String(data: encoded, encoding: .utf8), "\"imported\"")
    }

    func testIDMustBeUppercase32CharacterHex() {
        let badRecord = record(id: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", filename: "AppView.swift")

        XCTAssertThrowsError(try PrivateDiscriminatorCSV.write([badRecord])) { error in
            XCTAssertEqual(
                error as? PrivateDiscriminatorCSVError,
                .invalidID(row: 2, id: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
            )
        }
    }

    func testDuplicateIDIsRejected() {
        let records = [
            record(id: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", filename: "AppView.swift"),
            record(id: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", filename: "OtherView.swift"),
        ]

        XCTAssertThrowsError(try PrivateDiscriminatorCSV.write(records)) { error in
            XCTAssertEqual(
                error as? PrivateDiscriminatorCSVError,
                .duplicateID(row: 3, id: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
            )
        }
    }

    func testDuplicateFilenameIsRejected() {
        let records = [
            record(id: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", filename: "AppView.swift"),
            record(id: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", filename: "AppView.swift"),
        ]

        XCTAssertThrowsError(try PrivateDiscriminatorCSV.write(records)) { error in
            XCTAssertEqual(
                error as? PrivateDiscriminatorCSVError,
                .duplicateFilename(row: 3, filename: "AppView.swift")
            )
        }
    }

    func testModuleIndexLoadsValidatedRecords() throws {
        let csv = """
        id,filename,created_at,updated_at,created_by,updated_by
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,AppView.swift,2026-05-10T00:00:00Z,2026-05-10T00:00:00Z,user,user

        """

        let index = try PrivateDiscriminatorModuleIndex.read(moduleName: "DemoKit", csvText: csv)

        XCTAssertEqual(index.moduleName, "DemoKit")
        XCTAssertEqual(index.record(forID: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")?.filename, "AppView.swift")
    }

    func testExampleFixtureParsesAndMatchesModuleFilenames() throws {
        let csv = try fixtureCSV(named: "LookInsidePrivateDiscriminatorExample")
        let records = try PrivateDiscriminatorCSV.read(csv)
        let index = try PrivateDiscriminatorModuleIndex(
            moduleName: "LookInsidePrivateDiscriminatorExample",
            records: records
        )
        let headerRecord = try XCTUnwrap(index.record(forFilename: "HeaderView.swift"))
        let createdAt = try XCTUnwrap(PrivateDiscriminatorCSV.date(fromTimestamp: "2026-05-10T05:52:12Z"))
        let updatedAt = try XCTUnwrap(PrivateDiscriminatorCSV.date(fromTimestamp: "2026-05-10T15:11:35Z"))

        XCTAssertEqual(records.count, 8)
        XCTAssertEqual(headerRecord.id, "1872228C042F185147A87CDC56B4260B")
        XCTAssertEqual(headerRecord.created_at, createdAt)
        XCTAssertEqual(headerRecord.updated_at, updatedAt)
        XCTAssertEqual(headerRecord.created_by, "user")
        XCTAssertEqual(headerRecord.updated_by, "user")

        let cache = PrivateDiscriminatorVerificationCache(bucketCount: records.count)
        for record in records {
            let verification = cache.verify(
                id: record.id,
                module: index.moduleName,
                filename: record.filename
            )
            XCTAssertTrue(verification.isMatch, "\(record.filename) should match \(record.id)")
            XCTAssertEqual(verification.computedID, record.id)
            XCTAssertNil(verification.failureReason)
        }
    }

    func testVerifierComputesExpectedMD5() {
        let cache = PrivateDiscriminatorVerificationCache(bucketCount: 20)
        let id = PrivateDiscriminatorVerificationCache.privateDiscriminatorID(
            module: "DemoKit",
            filename: "HeaderView.swift"
        )

        let result = cache.verify(id: id, module: "DemoKit", filename: "HeaderView.swift")

        XCTAssertTrue(result.isMatch)
        XCTAssertNil(result.failureReason)
        XCTAssertEqual(result.computedID, id)
    }

    func testVerifierReportsMismatch() {
        let cache = PrivateDiscriminatorVerificationCache(bucketCount: 20)

        let result = cache.verify(
            id: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
            module: "DemoKit",
            filename: "HeaderView.swift"
        )

        XCTAssertFalse(result.isMatch)
        XCTAssertEqual(result.failureReason, .mismatch)
        XCTAssertNotNil(result.computedID)
    }

    func testVerifierCacheHonorsBucketLimit() {
        let cache = PrivateDiscriminatorVerificationCache(bucketCount: 2)

        _ = cache.verify(id: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", module: "DemoKit", filename: "A.swift")
        _ = cache.verify(id: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", module: "DemoKit", filename: "B.swift")
        _ = cache.verify(id: "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC", module: "DemoKit", filename: "C.swift")

        XCTAssertEqual(cache.cachedEntryCount, 2)
    }

    private func record(
        id: String,
        filename: String,
        createdAt: Date = PrivateDiscriminatorCSV.date(fromTimestamp: "2026-05-10T00:00:00Z")!
    ) -> PrivateDiscriminatorRecord {
        PrivateDiscriminatorRecord(
            id: id,
            filename: filename,
            created_at: createdAt,
            updated_at: PrivateDiscriminatorCSV.date(fromTimestamp: "2026-05-10T00:00:00Z")!,
            created_by: "user",
            updated_by: "user"
        )
    }

    private func fixtureCSV(named name: String) throws -> String {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "csv"))
        return try String(contentsOf: url, encoding: .utf8)
    }
}
