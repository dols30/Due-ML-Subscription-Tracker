//
//  PreviewContainer.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

#if DEBUG
    import SwiftUI

    @MainActor
    struct PreviewContainer<Content: View>: View {
        @State private var store: SubscriptionStore
        private let content: Content

        init(@ViewBuilder content: () -> Content) {
            let fileURL = FileManager.default.temporaryDirectory
                .appending(path: "due-preview-\(UUID().uuidString).json")
            let defaults = UserDefaults(suiteName: "com.midterm.due.previews") ?? .standard
            _store = State(
                initialValue: SubscriptionStore(
                    fileURL: fileURL, defaults: defaults, isTemporary: true))
            self.content = content()
        }

        var body: some View {
            content
                .environment(store)
                .tint(DueTheme.accent)
                .preferredColorScheme(.dark)
        }
    }
#endif
