# Due ML: Subscription Tracker

A SwiftUI subscription and free-trial tracker with on-device natural-language entry. Describe a subscription, review the extracted details, and save it.

> Netflix costs 15.99 USD per month, renews October 25, and remind me two days before.

## Run

Requires Xcode 16.2 or later and iOS 17 or later. Install [Git LFS](https://git-lfs.com/) before cloning to download the model weights.

```sh
git clone https://github.com/dols30/Due-ML-Subscription-Tracker.git
cd Due-ML-Subscription-Tracker
git lfs pull
open Due.xcodeproj
```

Select the **Due** scheme and an iPhone simulator, then press Run. For a physical device, select your signing team in Signing & Capabilities.

## Features

- Natural-language subscription entry with a review step before saving.
- Service browsing and manual entry.
- Subscription editing, search, filters, cancellation history, and deletion.
- Monthly and annual spending summaries, grouped by currency.
- Billing calendar, trial deadlines, and local reminders.
- CSV export, dark appearance, Dynamic Type, and VoiceOver labels.
- Local storage with no account or backend.

The app starts with an empty list. Missing or ambiguous details must be supplied in the editor. Natural-language entry runs locally; it does not send descriptions to a server.

## Model

The bundled model is the original Due v2 fine-tuned **DistilBERT base cased** token classifier, converted to Core ML. It extracts service, amount, currency, billing cycle, billing date, trial end, reminder, and plan type. Swift code tokenizes input, decodes BIO labels, and builds an editable draft.

Training used 3,796 synthetic descriptions. A separate 62-description development set selected the checkpoint and a 0.80 span-confidence threshold. The original 84-description final evaluation achieved **97.34% entity F1** and **85.71% complete-entry accuracy**. These scores measure extraction on a small authored benchmark.

The full-precision model weights are about 248 MB and are tracked with Git LFS. Inference uses the CPU. Physical-device latency and memory usage have not been measured.

- [Training notebook and dataset](https://github.com/dols30/Subscription-Information-Extraction-NLP)
- [Kaggle notebook](https://www.kaggle.com/code/bashcode223/nlp-subscription-information-extraction-distilbert?scriptVersionId=356506008)
- [Base model](https://huggingface.co/distilbert/distilbert-base-cased)
- [Model license: Apache 2.0](Due/Resources/NaturalEntry/ModelLicense.txt)

## Code organization

| Folder | Purpose |
|---|---|
| `Due/App` | App entry point and navigation |
| `Due/Features` | Overview, subscriptions, calendar, and settings |
| `Due/Models` | Subscription data, calculations, and form validation |
| `Due/Data` | Local persistence and service presets |
| `Due/Services/NaturalEntry` | Tokenizer, Core ML inference, date parsing, and draft creation |
| `Due/Resources/NaturalEntry` | Model package, vocabulary, and model license |
| `DueTests` | Subscription logic, persistence, tokenizer parity, and model extraction tests |
| `DueUITests` | Subscription flows and natural-language entry with review and fallback |

## Tests

```sh
xcodebuild -project Due.xcodeproj -scheme Due \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.3' \
  -derivedDataPath build test -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

The `-uitesting` launch argument isolates test records and disables persistence and notification scheduling.

Author: Dol Raj Bashyal
