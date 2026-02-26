1) Architecture overview
- SwiftUI iOS app with single root flow: `DreamOracleApp` -> `ContentView`.
- Shared app state is centralized in `DreamInterpreterViewModel`.
- Main UI is a tabbed shell: Home, Calendar, Dreams, Profile.
- Interpretation orchestration is in ViewModel, API calls in service layer.
- `OpenAIService` covers interpretation, follow-ups, and audio transcription.
- `GeminiImageService` handles AI artwork generation.
- Persistence is local (`UserDefaults`) for wallet and dream records.
- Credits/free quota are enforced locally in ViewModel.
- No backend/proxy layer is present; app calls external AI APIs directly.

2) Screen map
- Root: `ContentView`
- Tabs: `DreamHomeView`, `DreamCalendarView`, `DreamJournalHubView`, `DreamProfileView`
- Full-screen: `DreamComposerView`, `DreamInterpretationView`
- Drill-down: `DreamObjectAnalysisView` (from `DreamJournalHubView`)
- Present in code but not wired in root tab flow: `DreamDictionaryView`

3) File paths
- Interpretation logic:
  - `DreamOracle/Sources/DreamInterpreterViewModel.swift`
  - `DreamOracle/Sources/OpenAIService.swift`
- Image generation:
  - `DreamOracle/Sources/GeminiImageService.swift`
  - `DreamOracle/Sources/DreamInterpreterViewModel.swift`
  - `DreamOracle/Sources/DreamInterpretationView.swift`
- Credits/counters:
  - `DreamOracle/Sources/DreamInterpreterViewModel.swift`
  - `DreamOracle/Sources/DreamProfileView.swift`
  - `DreamOracle/Sources/DreamModels.swift`

4) StoreKit presence
- No StoreKit import or StoreKit purchase flow found.

5) Top security risks
- Hardcoded API secrets in `DreamOracle/Sources/OwnerSecrets.swift`.
- Provider API keys used directly in client-side requests.
- Credit purchase is local-only state mutation (tamperable).
- Sensitive dream/wallet data stored in `UserDefaults` without encryption.
- No visible server-side auth/rate-limit control boundary.
