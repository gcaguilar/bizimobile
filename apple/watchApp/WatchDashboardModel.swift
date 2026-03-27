import BiziSharedCore
import Foundation
import SwiftUI

@MainActor
final class WatchDashboardModel: ObservableObject {
    private let graph: any WatchGraphClient
    @Published private(set) var nearbyStations: [WatchStationSnapshot] = []
    @Published private(set) var favoriteStations: [WatchStationSnapshot] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    init(graph: any WatchGraphClient = BiziWatchGraph.shared) {
        self.graph = graph
    }

    func refresh(
        favoriteIds: Set<String>,
        homeStationId: String? = nil,
        workStationId: String? = nil
    ) async {
        withAnimation(.easeOut(duration: 0.18)) {
            isLoading = true
            errorMessage = nil
        }
        do {
            let nearbyStations = try await graph.nearbyStations(limit: 5)
            let favoriteStations = try await graph.favoriteStations(favoriteIds: favoriteIds)
                .sorted { lhs, rhs in
                    let lhsPriority = lhs.favoritePriority(homeStationId: homeStationId, workStationId: workStationId)
                    let rhsPriority = rhs.favoritePriority(homeStationId: homeStationId, workStationId: workStationId)
                    if lhsPriority != rhsPriority {
                        return lhsPriority > rhsPriority
                    }
                    if lhs.distanceMeters != rhs.distanceMeters {
                        return lhs.distanceMeters < rhs.distanceMeters
                    }
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
            withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                self.nearbyStations = nearbyStations
                self.favoriteStations = favoriteStations
            }
        } catch {
            withAnimation(.easeOut(duration: 0.18)) {
                errorMessage = error.localizedDescription
                nearbyStations = []
                favoriteStations = []
            }
        }
        withAnimation(.easeOut(duration: 0.18)) {
            isLoading = false
        }
    }
}

private extension WatchStationSnapshot {
    func favoritePriority(homeStationId: String?, workStationId: String?) -> Int {
        if id == homeStationId { return 400 }
        if id == workStationId { return 380 }
        return 100
    }
}
