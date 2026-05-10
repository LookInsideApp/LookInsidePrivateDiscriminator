# LookInsidePrivateDiscriminator Example

This iOS fixture app is intentionally small and inspection-friendly. It has a UIKit tab with file-local private `UIView` subclasses and a SwiftUI tab with primitive controls that are backed by UIKit views.

Install the pinned Tuist version and generate the project:

```sh
cd Example
mise install
mise x -- tuist generate --no-open
```

If your shell has mise shims activated, `tuist generate --no-open` works from this directory too.

The app bundles `LookInsideServer` from `https://github.com/LookInsideApp/LookInside-Release.git` so it can be inspected by LookInside while exercising private-discriminator guesses.
