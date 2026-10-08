//
//  ServiceIcon.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/2/26.
//

import SwiftUI

struct ServiceIcon: View {
    let item: Subscription
    var size: CGFloat = 48
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.43, weight: .medium))
            .foregroundStyle(DueTheme.accent)
            .frame(width: size, height: size)
            .background(DueTheme.softBlue, in: RoundedRectangle(cornerRadius: size * 0.3))
            .accessibilityHidden(true)
    }

    private var symbol: String {
        let value = item.name.lowercased()
        if value.contains("music") { return "music.note" }
        if value.contains("icloud") { return "icloud.fill" }
        if value.contains("netflix") { return "n.square.fill" }
        if value.contains("youtube") { return "play.rectangle.fill" }
        if value.contains("notion") { return "doc.text.fill" }
        if value.contains("adobe") { return "a.square.fill" }
        if value.contains("headspace") { return "sun.max.fill" }
        if value.contains("spotify") { return "waveform" }
        if value.contains("todoist") { return "checkmark.circle" }
        if value.contains("evernote") { return "note.text" }
        if value.contains("obsidian") { return "diamond" }
        if value == "bear" { return "pencil.line" }
        return item.category.symbol
    }
}
