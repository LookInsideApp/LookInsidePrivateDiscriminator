import CryptoKit
import Foundation

public enum PrivateDiscriminatorVerificationFailureReason: String, Equatable, Sendable {
    case invalidID
    case invalidModuleName
    case invalidFilename
    case mismatch
}

public struct PrivateDiscriminatorVerificationResult: Equatable, Sendable {
    public let id: String
    public let module: String
    public let filename: String
    public let computedID: String?
    public let isMatch: Bool
    public let failureReason: PrivateDiscriminatorVerificationFailureReason?

    public var isValidInput: Bool {
        switch failureReason {
        case .invalidID, .invalidModuleName, .invalidFilename:
            return false
        case .mismatch, nil:
            return true
        }
    }
}

public final class PrivateDiscriminatorVerificationCache: @unchecked Sendable {
    private struct CacheKey: Hashable {
        var id: String
        var module: String
        var filename: String
    }

    private let lock = NSLock()
    private let bucketCount: Int
    private var values: [CacheKey: PrivateDiscriminatorVerificationResult] = [:]
    private var order: [CacheKey] = []

    public init(bucketCount: Int = 20) {
        self.bucketCount = max(1, bucketCount)
    }

    public var cachedEntryCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return values.count
    }

    public func verify(id: String, module: String, filename: String) -> PrivateDiscriminatorVerificationResult {
        let normalizedID = id.uppercased()
        let key = CacheKey(id: normalizedID, module: module, filename: filename)

        lock.lock()
        if let cached = values[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let result = Self.makeResult(id: normalizedID, module: module, filename: filename)

        lock.lock()
        values[key] = result
        order.append(key)
        while order.count > bucketCount {
            let staleKey = order.removeFirst()
            values.removeValue(forKey: staleKey)
        }
        lock.unlock()

        return result
    }

    public static func privateDiscriminatorID(module: String, filename: String) -> String {
        let bytes = Insecure.MD5.hash(data: Data((module + filename).utf8))
        return bytes.map { String(format: "%02X", $0) }.joined()
    }

    private static func makeResult(id: String, module: String, filename: String) -> PrivateDiscriminatorVerificationResult {
        guard PrivateDiscriminatorCSV.isValidID(id) else {
            return PrivateDiscriminatorVerificationResult(
                id: id,
                module: module,
                filename: filename,
                computedID: nil,
                isMatch: false,
                failureReason: .invalidID
            )
        }
        guard PrivateDiscriminatorModuleIndex.isValidModuleName(module) else {
            return PrivateDiscriminatorVerificationResult(
                id: id,
                module: module,
                filename: filename,
                computedID: nil,
                isMatch: false,
                failureReason: .invalidModuleName
            )
        }
        guard PrivateDiscriminatorCSV.isValidFilename(filename) else {
            return PrivateDiscriminatorVerificationResult(
                id: id,
                module: module,
                filename: filename,
                computedID: nil,
                isMatch: false,
                failureReason: .invalidFilename
            )
        }

        let computedID = privateDiscriminatorID(module: module, filename: filename)
        let isMatch = computedID == id
        return PrivateDiscriminatorVerificationResult(
            id: id,
            module: module,
            filename: filename,
            computedID: computedID,
            isMatch: isMatch,
            failureReason: isMatch ? nil : .mismatch
        )
    }
}
