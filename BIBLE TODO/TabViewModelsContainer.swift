import Foundation

/// Holds tab `ViewModel`s for the main shell so switching tabs does not recreate them or refetch on every visit.
@MainActor
final class TabViewModelsContainer {
    let home: HomeViewModel
    let journey: JourneyViewModel

    init(service: BibleService, persistence: AppPersistence) {
        home = HomeViewModel(service: service, persistence: persistence)
        journey = JourneyViewModel(service: service, persistence: persistence)
    }
}
