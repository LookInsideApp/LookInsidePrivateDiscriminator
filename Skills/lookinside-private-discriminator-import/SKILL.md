---
name: lookinside-private-discriminator-import
description: Convert a Swift source folder into LookInside private discriminator CSV files using the LookInsidePrivateDiscriminator schema.
---

# LookInside Private Discriminator Import

Use this skill when a user wants to prepare or validate a private discriminator CSV outside the LookInside app.

## Output Schema

Emit exactly this header order:

```csv
id,filename,created_at,updated_at,created_by,updated_by
```

Rules:
- One CSV represents one module.
- Do not include a `module` column.
- `filename` is basename-only, usually a `.swift` filename.
- `id` is uppercase 32-character hexadecimal.
- Timestamps use UTC seconds: `yyyy-MM-dd'T'HH:mm:ss'Z'`.
- Imported rows use `created_by=imported` and `updated_by=imported`.
- User-authored rows use `created_by=user` and `updated_by=user`.

## Import Workflow

1. Ask for the module name and local folder if either is missing.
2. Recursively scan the folder for `.swift` files.
3. Use basename-only filenames and de-duplicate filenames before writing.
4. Compute each row id as uppercase MD5 of `module + filename`.
5. Preserve existing `created_at` and `created_by` values when reimporting over an existing CSV.
6. Write deterministic output sorted by filename.
7. Validate the resulting text with `LookInsidePrivateDiscriminator.PrivateDiscriminatorCSV.read(_:)` when the package is available.

Prefer the LookInside app Settings importer when working inside the app. This skill is for repository, CI, and one-off conversion workflows.
