# LookInsidePrivateDiscriminator

Schema and CSV helpers for LookInside private-discriminator indexes.

This package intentionally contains no UI, app settings, filesystem import flow, or `swift-pd-guess` dependency. LookInside owns those app-level integrations.

## CSV Schema

Each CSV represents one module and must use this header order:

```csv
id,filename,created_at,updated_at,created_by,updated_by
```

Validation rules:
- `id` is uppercase 32-character hexadecimal.
- `filename` is basename-only.
- Timestamps use UTC seconds: `yyyy-MM-dd'T'HH:mm:ss'Z'`.
- Authors use `PrivateDiscriminatorRecordAuthor`; built-in values are `user` and `imported`.
- IDs and filenames must be unique within a module CSV.

Use `PrivateDiscriminatorCSV.read(_:)`, `PrivateDiscriminatorCSV.write(_:)`, and `PrivateDiscriminatorModuleIndex.read(moduleName:csvText:)` for strict validation and deterministic output.
`PrivateDiscriminatorRecord.created_at` and `updated_at` are `Date` values in Swift; CSV parsing and writing convert them at the schema boundary.

Use `PrivateDiscriminatorVerificationCache` to verify that `MD5(module + filename)` matches a private-discriminator ID. The default cache keeps 20 recent verification entries.

## iOS Example

`Example/` contains a Tuist-generated iOS fixture app with UIKit and SwiftUI tabs. It bundles `LookInsideServer` from `https://github.com/LookInsideApp/LookInside-Release.git` and can be generated with:

```sh
cd Example
mise install
mise x -- tuist generate --no-open
```
