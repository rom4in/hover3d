# Development Guidelines

- Use MVVM for feature and screen structure, keeping view presentation separate from state and business logic.
- Apply Clean Architecture where it provides a clear benefit, but avoid over-engineering abstractions for simple flows.
- Keep SwiftUI `View.body` as lean as possible. Extract meaningful sections into small computed properties such as `private var content: some View { ... }`.
- Keep each SwiftUI `View` in its own Swift file and include a `#Preview` for it.
- Add reusable button styles and view modifiers as `View` extensions.
