import Foundation
import CoreLocation
import Combine

final class LocationManager:
    NSObject,
    ObservableObject {

    // MARK: - Properties

    private let manager =
        CLLocationManager()

    // MARK: - Published State

    @Published var authorizationStatus:
        CLAuthorizationStatus

    // MARK: - Init

    override init() {

        authorizationStatus =
            manager.authorizationStatus

        super.init()

        manager.delegate = self

        manager.desiredAccuracy =
            kCLLocationAccuracyBest
    }

    // MARK: - Permissions

    func requestLocationAccess() {

        manager.requestWhenInUseAuthorization()

        manager.startUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager:
    CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {

        authorizationStatus =
            manager.authorizationStatus

        switch manager.authorizationStatus {

        case .authorizedAlways,
             .authorizedWhenInUse:

            manager.startUpdatingLocation()

        default:

            break
        }
    }
}
