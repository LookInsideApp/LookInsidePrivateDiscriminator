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
        let badRecord = record(
            id: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
            filename: "AppView.swift",
            createdAt: "2026-05-10T00:00:00.000Z"
        )

        XCTAssertThrowsError(try PrivateDiscriminatorCSV.write([badRecord])) { error in
            XCTAssertEqual(
                error as? PrivateDiscriminatorCSVError,
                .invalidTimestamp(row: 2, field: "created_at", value: "2026-05-10T00:00:00.000Z")
            )
        }
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
        createdAt: String = "2026-05-10T00:00:00Z"
    ) -> PrivateDiscriminatorRecord {
        PrivateDiscriminatorRecord(
            id: id,
            filename: filename,
            created_at: createdAt,
            updated_at: "2026-05-10T00:00:00Z",
            created_by: "user",
            updated_by: "user"
        )
    }
}
