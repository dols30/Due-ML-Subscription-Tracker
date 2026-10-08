//
//  EntryTokenizer.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/8/26.
//

import Foundation

struct EntryToken {
    let id: Int
    let range: NSRange
}

struct EntryEncoding {
    let tokens: [EntryToken]
    let mask: [Int]
}

struct EntryTokenizer {
    // WordPiece compares exact bytes; Swift String keys equate composed and decomposed accents.
    private let vocabulary: [Data: Int]
    private let specialTokens = [
        "[PAD]": 0, "[UNK]": 100, "[CLS]": 101, "[SEP]": 102, "[MASK]": 103,
    ]
    private let length = 128

    init(vocabulary: String) {
        self.vocabulary = Dictionary(
            uniqueKeysWithValues: vocabulary.components(separatedBy: "\n").enumerated().map {
                (Data($0.element.utf8), $0.offset)
            })
    }

    func encode(_ text: String) throws -> EntryEncoding {
        var tokens = [EntryToken(id: 101, range: NSRange(location: 0, length: 0))]
        var word: [Unit] = []
        let scalars = Array(text.unicodeScalars)
        var offset = 0
        var index = 0

        func flush() {
            guard !word.isEmpty else { return }
            tokens.append(contentsOf: pieces(word))
            word.removeAll(keepingCapacity: true)
        }

        while index < scalars.count {
            let scalar = scalars[index]
            let remaining = String(String.UnicodeScalarView(scalars[index...]))
            if let special = specialTokens.keys.first(where: { remaining.hasPrefix($0) }) {
                flush()
                tokens.append(
                    EntryToken(
                        id: specialTokens[special]!,
                        range: NSRange(location: offset, length: special.utf16.count)))
                index += special.unicodeScalars.count
                offset += special.utf16.count
                continue
            }
            let width = scalar.value > 0xFFFF ? 2 : 1
            let unit = Unit(value: scalar, start: offset, end: offset + width)
            index += 1
            offset += width
            if isWhitespace(scalar) {
                flush()
            } else if scalar.value == 0 || scalar.value == 0xFFFD
                || scalar.properties.generalCategory == .control
                || scalar.properties.generalCategory == .format
            {
                continue
            } else if isPunctuation(scalar) || isChinese(scalar) {
                flush()
                tokens.append(contentsOf: pieces([unit]))
            } else {
                word.append(unit)
            }
        }
        flush()
        tokens.append(EntryToken(id: 102, range: NSRange(location: 0, length: 0)))
        guard tokens.count <= length else { throw EntryError.descriptionTooLong }
        let count = tokens.count
        tokens += Array(
            repeating: EntryToken(id: 0, range: NSRange(location: 0, length: 0)),
            count: length - count)
        return EntryEncoding(
            tokens: tokens,
            mask: Array(repeating: 1, count: count) + Array(repeating: 0, count: length - count))
    }

    private struct Unit {
        let value: Unicode.Scalar
        let start: Int
        let end: Int
    }

    private func pieces(_ word: [Unit]) -> [EntryToken] {
        let whole = NSRange(location: word[0].start, length: word.last!.end - word[0].start)
        guard word.count <= 100 else { return [EntryToken(id: 100, range: whole)] }
        var result: [EntryToken] = []
        var start = 0
        while start < word.count {
            var end = word.count
            var found: EntryToken?
            while end > start {
                let value = String(String.UnicodeScalarView(word[start..<end].map(\.value)))
                if let id = vocabulary[Data(((start == 0 ? "" : "##") + value).utf8)] {
                    found = EntryToken(
                        id: id,
                        range: NSRange(
                            location: word[start].start,
                            length: word[end - 1].end - word[start].start))
                    break
                }
                end -= 1
            }
            guard let found else { return [EntryToken(id: 100, range: whole)] }
            result.append(found)
            start = end
        }
        return result
    }

    private func isWhitespace(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value == 9 || scalar.value == 10 || scalar.value == 13
            || scalar.properties.generalCategory == .spaceSeparator
    }

    private func isPunctuation(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        if (33...47).contains(value) || (58...64).contains(value) || (91...96).contains(value)
            || (123...126).contains(value)
        {
            return true
        }
        switch scalar.properties.generalCategory {
        case .connectorPunctuation, .dashPunctuation, .openPunctuation, .closePunctuation,
            .initialPunctuation, .finalPunctuation, .otherPunctuation:
            return true
        default: return false
        }
    }

    private func isChinese(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        return (0x4E00...0x9FFF).contains(value) || (0x3400...0x4DBF).contains(value)
            || (0x20000...0x2A6DF).contains(value) || (0x2A700...0x2B73F).contains(value)
            || (0x2B740...0x2B81F).contains(value) || (0x2B820...0x2CEAF).contains(value)
            || (0xF900...0xFAFF).contains(value) || (0x2F800...0x2FA1F).contains(value)
    }
}
