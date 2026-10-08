//
//  ServicePresets.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import Foundation

struct ServicePreset: Identifiable {
    let name: String
    let category: ServiceCategory
    let managementURL: String

    var id: String { name }

    static let all: [ServicePreset] = [
        ServicePreset(
            name: "Apple Music", category: .entertainment,
            managementURL: "https://apps.apple.com/account/subscriptions"),
        ServicePreset(
            name: "Netflix", category: .entertainment,
            managementURL: "https://www.netflix.com/youraccount"),
        ServicePreset(
            name: "iCloud+", category: .storage, managementURL: "https://support.apple.com/icloud"),
        ServicePreset(
            name: "YouTube Premium", category: .entertainment,
            managementURL: "https://www.youtube.com/paid_memberships"),
        ServicePreset(
            name: "Notion", category: .productivity, managementURL: "https://www.notion.so"),
        ServicePreset(
            name: "Spotify", category: .entertainment,
            managementURL: "https://www.spotify.com/account/"),
        ServicePreset(
            name: "Dropbox", category: .storage,
            managementURL: "https://www.dropbox.com/account/plan"),
        ServicePreset(
            name: "Todoist", category: .productivity,
            managementURL: "https://app.todoist.com"),
        ServicePreset(
            name: "Evernote", category: .productivity,
            managementURL: "https://www.evernote.com/Settings.action"),
        ServicePreset(
            name: "Obsidian", category: .productivity,
            managementURL: "https://obsidian.md/account"),
        ServicePreset(
            name: "Bear", category: .productivity,
            managementURL: "https://apps.apple.com/account/subscriptions"),
    ]
}
