import Foundation
import WatchConnectivity

@MainActor
final class WatchFavoritesSyncBridge: NSObject, ObservableObject, @preconcurrency WCSessionDelegate {
    static let shared = WatchFavoritesSyncBridge()
    static let favoritesCacheKey = "bizizaragoza.watch.favorite_ids"
    static let homeStationCacheKey = "bizizaragoza.watch.home_station_id"
    static let workStationCacheKey = "bizizaragoza.watch.work_station_id"

    @Published private(set) var favoriteIds: Set<String> = []
    @Published private(set) var homeStationId: String?
    @Published private(set) var workStationId: String?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.favoriteIds = Set(defaults.stringArray(forKey: Self.favoritesCacheKey) ?? [])
        self.homeStationId = defaults.string(forKey: Self.homeStationCacheKey)
        self.workStationId = defaults.string(forKey: Self.workStationCacheKey)
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        apply(context: session.receivedApplicationContext)
    }

    func requestRoute(to stationId: String) -> Bool {
        guard WCSession.default.activationState == .activated else { return false }
        var context = WCSession.default.receivedApplicationContext
        context["favorite_ids"] = Array(favoriteIds)
        context["home_station_id"] = homeStationId
        context["work_station_id"] = workStationId
        context["route_station_id"] = stationId
        context["route_requested_at"] = Date().timeIntervalSince1970
        do {
            try WCSession.default.updateApplicationContext(context)
            return true
        } catch {
            return false
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        apply(context: session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(context: applicationContext)
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func apply(context: [String: Any]) {
        if let ids = context["favorite_ids"] as? [String] {
            favoriteIds = Set(ids)
            defaults.set(ids, forKey: Self.favoritesCacheKey)
        }
        if let homeStationId = context["home_station_id"] as? String, !homeStationId.isEmpty {
            self.homeStationId = homeStationId
            defaults.set(homeStationId, forKey: Self.homeStationCacheKey)
        }
        if let workStationId = context["work_station_id"] as? String, !workStationId.isEmpty {
            self.workStationId = workStationId
            defaults.set(workStationId, forKey: Self.workStationCacheKey)
        }
    }
}
