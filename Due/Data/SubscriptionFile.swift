//
//  SubscriptionFile.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import Foundation

final class SubscriptionFile {
    private let url: URL
    private var needsRecoveryCopy = false

    init(url: URL? = nil) {
        let folder = URL.applicationSupportDirectory.appending(
            path: "Due", directoryHint: .isDirectory)
        self.url = url ?? folder.appending(path: "subscriptions.json")
    }

    func load() throws -> [Subscription] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            return try JSONDecoder().decode([Subscription].self, from: Data(contentsOf: url))
        } catch {
            needsRecoveryCopy = true
            throw error
        }
    }

    func save(_ subscriptions: [Subscription]) throws {
        let folder = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if needsRecoveryCopy {
            let recoveryURL = folder.appending(
                path: "subscriptions-recovery-\(UUID().uuidString).json")
            try FileManager.default.copyItem(at: url, to: recoveryURL)
            needsRecoveryCopy = false
        }
        let data = try JSONEncoder().encode(subscriptions)
        try data.write(
            to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
