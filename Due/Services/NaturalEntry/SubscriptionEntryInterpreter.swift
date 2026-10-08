//
//  SubscriptionEntryInterpreter.swift
//  Due
//
//  Created by Dol Raj Bashyal on 10/8/26.
//

import CoreML
import Foundation

struct EntryEntity {
    let field: String
    let text: String
    let confidence: Double
}

enum EntryError: LocalizedError {
    case descriptionTooLong, modelUnavailable, noDetails

    var errorDescription: String? {
        switch self {
        case .descriptionTooLong:
            "This description is too long. Try one subscription in a few sentences."
        case .modelUnavailable:
            "Description entry is unavailable. You can enter the details manually."
        case .noDetails:
            "No subscription details were recognized. Include a service name, price, and billing cycle, or enter the details manually."
        }
    }
}

actor SubscriptionEntryInterpreter {
    static let shared = SubscriptionEntryInterpreter()
    private var model: MLModel?
    private var tokenizer: EntryTokenizer?
    private let fields = [
        "SERVICE", "AMOUNT", "CURRENCY", "CYCLE", "BILLING_DATE", "TRIAL_END", "REMINDER",
        "PLAN_TYPE",
    ]

    func extract(_ text: String) throws -> [EntryEntity] {
        try Task.checkCancellation()
        guard text.count <= 2000 else { throw EntryError.descriptionTooLong }
        try loadResources()
        guard let model, let tokenizer else { throw EntryError.modelUnavailable }
        let encoding = try tokenizer.encode(text)
        let ids = try MLMultiArray(shape: [1, 128], dataType: .int32)
        let mask = try MLMultiArray(shape: [1, 128], dataType: .int32)
        for index in encoding.tokens.indices {
            ids[index] = NSNumber(value: encoding.tokens[index].id)
            mask[index] = NSNumber(value: encoding.mask[index])
        }
        let input = try MLDictionaryFeatureProvider(dictionary: [
            "input_ids": ids, "attention_mask": mask,
        ])
        let output = try model.prediction(from: input)
        try Task.checkCancellation()
        guard let logits = output.featureValue(for: "logits")?.multiArrayValue,
            logits.shape.map(\.intValue) == [1, 128, 17]
        else { throw EntryError.modelUnavailable }
        return decode(text, tokens: encoding.tokens, logits: logits)
    }

    private func loadResources() throws {
        if model == nil {
            guard let url = Bundle.main.url(forResource: "DueEntry", withExtension: "mlmodelc")
            else { throw EntryError.modelUnavailable }
            let configuration = MLModelConfiguration()
            // CPU inference preserves the full-precision path checked during conversion.
            configuration.computeUnits = .cpuOnly
            model = try MLModel(contentsOf: url, configuration: configuration)
        }
        if tokenizer == nil {
            guard let url = Bundle.main.url(forResource: "EntryVocabulary", withExtension: "txt")
            else { throw EntryError.modelUnavailable }
            tokenizer = EntryTokenizer(vocabulary: try String(contentsOf: url, encoding: .utf8))
        }
    }

    private func decode(_ text: String, tokens: [EntryToken], logits: MLMultiArray) -> [EntryEntity]
    {
        var result: [EntryEntity] = []
        var current: (field: String, range: NSRange, confidence: Double)?
        func flush() {
            if let entity = current, entity.confidence >= 0.80 {
                result.append(
                    EntryEntity(
                        field: entity.field, text: (text as NSString).substring(with: entity.range),
                        confidence: entity.confidence))
            }
            current = nil
        }
        for (index, token) in tokens.enumerated() {
            guard token.range.length > 0 else {
                flush()
                continue
            }
            let values = (0..<17).map {
                logits[[0, NSNumber(value: index), NSNumber(value: $0)]].doubleValue
            }
            let label = values.indices.max(by: { values[$0] < values[$1] })!
            guard label > 0 else {
                flush()
                continue
            }
            let maximum = values[label]
            let confidence = 1 / values.reduce(0) { $0 + exp($1 - maximum) }
            let field = fields[(label - 1) / 2]
            let continuing = label % 2 == 0
            if continuing, let entity = current, entity.field == field {
                current = (
                    field,
                    NSRange(
                        location: entity.range.location,
                        length: NSMaxRange(token.range) - entity.range.location),
                    min(entity.confidence, confidence)
                )
            } else {
                flush()
                current = (field, token.range, confidence)
            }
        }
        flush()
        return result
    }
}
