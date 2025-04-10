//
//  ContentView.swift
//  SimpLink
//
//  Created by Aulia Nisrina Rosanita on 10/04/25.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

// MARK: - Data Models
struct BusStop: Identifiable {
    let id: String
    let name: String
    let location: CLLocationCoordinate2D
}

struct BusRoute {
    let id: String
    let name: String
    let stops: [BusStop]
    let color: UIColor
    
    func polylineBetween(start: BusStop, end: BusStop) -> MKPolyline? {
        guard let startIdx = stops.firstIndex(where: { $0.id == start.id }),
              let endIdx = stops.firstIndex(where: { $0.id == end.id }) else { return nil }
        
        let range = startIdx < endIdx ? startIdx...endIdx : endIdx...startIdx
        let coordinates = stops[range].map { $0.location }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    func stopsBetween(start: BusStop, end: BusStop) -> [BusStop] {
        guard let startIdx = stops.firstIndex(where: { $0.id == start.id }),
              let endIdx = stops.firstIndex(where: { $0.id == end.id }) else { return [] }
        
        let range = startIdx < endIdx ? startIdx...endIdx : endIdx...startIdx
        return Array(stops[range])
    }
}

extension UIColor {
    static let route1 = UIColor(hex: "#213284")
    static let route2 = UIColor(hex: "#C72C2F")
    static let route3 = UIColor(hex: "#EB5B00")
    static let route4 = UIColor(hex: "#2D8D28")
    static let route5 = UIColor(hex: "#500073")
    static let route6 = UIColor(hex: "#FFE31A")
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexFormatted.hasPrefix("#") {
            hexFormatted.removeFirst()
        }
        
        assert(hexFormatted.count == 6, "Invalid hex code.")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

struct RouteStep: Identifiable {
    let id = UUID()
    let time: String
    let location: String
    let address: String?
    let duration: String?
    let transportType: TransportType
    let stops: [String]?
    let coordinate: CLLocationCoordinate2D?
    
    enum TransportType {
        case walk, bus, destination
    }
}

struct SuggestedRoute: Identifiable {
    let id = UUID()
    let route: BusRoute
    let startStop: BusStop
    let endStop: BusStop
    let walkingTimeToStart: TimeInterval
    let busTravelTime: TimeInterval
    let walkingTimeToDestination: TimeInterval
    let totalTime: TimeInterval
    let schedules: [String]
    
    var formattedTotalTime: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: totalTime) ?? ""
    }
}

// MARK: - Route Planner
class RoutePlanner: NSObject, ObservableObject {
    @Published var routes: [MKPolyline] = []
    @Published var routeSteps: [RouteStep] = []
    @Published var suggestedRoutes: [SuggestedRoute] = []
    @Published var showBusStops: Bool = false
    @Published var showDrivingRoute: Bool = false
    @Published var drivingRoute: MKPolyline?
    @Published var visibleBusStops: [BusStop] = []
    @Published var currentRoute: BusRoute?
    @Published var currentRouteColor: Color = .gray
    
    public let bsdBusStops: [BusStop]
    public let bsdLinkRoutes: [BusRoute]
    
    override init() {
        // Initialize BSD Link stops
        self.bsdBusStops = [
            BusStop(id: "BS01", name: "Intermoda", location: CLLocationCoordinate2D(latitude: -6.319902912486388, longitude: 106.64371452384238)),
            BusStop(id: "BS02", name: "Cosmo", location: CLLocationCoordinate2D(latitude: -6.312098624472068, longitude: 106.64866097703134)),
            BusStop(id: "BS03", name: "Verdant View", location: CLLocationCoordinate2D(latitude: -6.3135382058171885, longitude: 106.64862335719445)),
            BusStop(id: "BS04", name: "Eternity", location: CLLocationCoordinate2D(latitude: -6.314804674128097, longitude: 106.64629166413174)),
            BusStop(id: "BS05", name: "Simplicity 2", location: CLLocationCoordinate2D(latitude: -6.313048540439234, longitude: 106.6425585810072)),
            BusStop(id: "BS06", name: "Edutown 1", location: CLLocationCoordinate2D(latitude: -6.3024419386956625, longitude: 106.64175422053961)),
            BusStop(id: "BS07", name: "Edutown 2", location: CLLocationCoordinate2D(latitude: -6.301401045958158, longitude: 106.64161410520205)),
            BusStop(id: "BS08", name: "ICE 1", location: CLLocationCoordinate2D(latitude: -6.297305991629695, longitude: 106.63663993540509)),
            BusStop(id: "BS09", name: "ICE 2", location: CLLocationCoordinate2D(latitude: -6.301798026906297, longitude: 106.63537576609392)),
            BusStop(id: "BS10", name: "ICE Business Park", location: CLLocationCoordinate2D(latitude: -6.303322716671507, longitude: 106.63447285075002)),
            BusStop(id: "BS11", name: "ICE 6", location: CLLocationCoordinate2D(latitude: -6.299214743448269, longitude: 106.63501661265211)),
            BusStop(id: "BS12", name: "ICE 5", location: CLLocationCoordinate2D(latitude: -6.296908022160658, longitude: 106.63614993540504)),
            BusStop(id: "BS13", name: "GOP 1", location: CLLocationCoordinate2D(latitude: -6.301333338511644, longitude: 106.6491341047173)),
            BusStop(id: "BS14", name: "SML Plaza", location: CLLocationCoordinate2D(latitude: -6.3018206829147045, longitude: 106.65107827402896)),
            BusStop(id: "BS15", name: "The Breeze", location: CLLocationCoordinate2D(latitude: -6.301369321397565, longitude: 106.65315717850528)),
            BusStop(id: "BS16", name: "CBD Timur 1", location: CLLocationCoordinate2D(latitude: -6.302837404339348, longitude: 106.65015285074993)),
            BusStop(id: "BS17", name: "CBD Timur 2", location: CLLocationCoordinate2D(latitude: -6.301030700563775, longitude: 106.64876966575737)),
            BusStop(id: "BS18", name: "GOP 2", location: CLLocationCoordinate2D(latitude: -6.301030700563775, longitude: 106.64876966575737)),
            BusStop(id: "BS19", name: "Nava Park 1", location: CLLocationCoordinate2D(latitude: -6.299573087873732, longitude: 106.64984707200264)),
            BusStop(id: "BS20", name: "SWA 2", location: CLLocationCoordinate2D(latitude: -6.299630155562472, longitude: 106.66243293720618)),
            BusStop(id: "BS21", name: "Giant", location: CLLocationCoordinate2D(latitude: -6.299347597253314, longitude: 106.6666351301771)),
            BusStop(id: "BS22", name: "Eka Hospital 1", location: CLLocationCoordinate2D(latitude: -6.299065485207059, longitude: 106.67031394722062)),
            BusStop(id: "BS23", name: "Puspita Loka", location: CLLocationCoordinate2D(latitude: -6.295377145696457, longitude: 106.67766489040433)),
            BusStop(id: "BS24", name: "Polsek Serpong", location: CLLocationCoordinate2D(latitude: -6.29603586772109, longitude: 106.68131227661276)),
            BusStop(id: "BS25", name: "Ruko Madrid", location: CLLocationCoordinate2D(latitude: -6.30196884684132, longitude: 106.6843857194694)),
            BusStop(id: "BS26", name: "Pasar Modern Timur", location: CLLocationCoordinate2D(latitude: -6.305348912751656, longitude: 106.68582347971999)),
            BusStop(id: "BS27", name: "Griya Loka 1", location: CLLocationCoordinate2D(latitude: -6.304835825560039, longitude: 106.68239886809873)),
            BusStop(id: "BS28", name: "Sektor 1.3", location: CLLocationCoordinate2D(latitude: -6.3057778200200305, longitude: 106.67991191028288)),
            BusStop(id: "BS29", name: "Griya Loka 2", location: CLLocationCoordinate2D(latitude: -6.304961931657671, longitude: 106.68151702006185)),
            BusStop(id: "BS30", name: "Santa Ursula 1", location: CLLocationCoordinate2D(latitude: -6.302771931151865, longitude: 106.6846528507499)),
            BusStop(id: "BS31", name: "Santa Ursula 2", location: CLLocationCoordinate2D(latitude: -6.300150681430886, longitude: 106.68316410471716)),
            BusStop(id: "BS32", name: "Sentra Onderdil", location: CLLocationCoordinate2D(latitude: -6.296683334763473, longitude: 106.6812441047167)),
            BusStop(id: "BS33", name: "Autopart", location: CLLocationCoordinate2D(latitude: -6.295531407562985, longitude: 106.67815419672414)),
            BusStop(id: "BS34", name: "Eka Hospital 2", location: CLLocationCoordinate2D(latitude: -6.299377523498342, longitude: 106.67009430185223)),
            BusStop(id: "BS35", name: "East Business District", location: CLLocationCoordinate2D(latitude: -6.299293336866941, longitude: 106.6669586814378)),
            BusStop(id: "BS36", name: "SWA 1", location: CLLocationCoordinate2D(latitude: -6.299345368339194, longitude: 106.6627761735028)),
            BusStop(id: "BS37", name: "Green Cove", location: CLLocationCoordinate2D(latitude: -6.2993814628841855, longitude: 106.65987993540543)),
            BusStop(id: "BS38", name: "AEON Mall 1", location: CLLocationCoordinate2D(latitude: -6.303120040327548, longitude: 106.64347755092595)),
            BusStop(id: "BS39", name: "CBD Barat 2", location: CLLocationCoordinate2D(latitude: -6.302221368040868, longitude: 106.64205317791004)),
            BusStop(id: "BS40", name: "Simplicity 1", location: CLLocationCoordinate2D(latitude: -6.312784863402183, longitude: 106.64423142592663)),
            BusStop(id: "BS41", name: "Greenwich Park Office", location: CLLocationCoordinate2D(latitude: -6.276622057947269, longitude: 106.63404)),
            BusStop(id: "BS42", name: "De Maja", location: CLLocationCoordinate2D(latitude: -6.280957532704141, longitude: 106.63961596488363)),
            BusStop(id: "BS43", name: "De Heliconia 2", location: CLLocationCoordinate2D(latitude: -6.283308041078943, longitude: 106.64115927116399)),
            BusStop(id: "BS44", name: "De Nara", location: CLLocationCoordinate2D(latitude: -6.285010028454532, longitude: 106.64400801314942)),
            BusStop(id: "BS45", name: "De Park 2", location: CLLocationCoordinate2D(latitude: -6.286975378906274, longitude: 106.64901655547753)),
            BusStop(id: "BS46", name: "Nava Park 2", location: CLLocationCoordinate2D(latitude: -6.290774052160064, longitude: 106.64982436896942)),
            BusStop(id: "BS47", name: "Giardina", location: CLLocationCoordinate2D(latitude: -6.291448715328519, longitude: 106.64828215809898)),
            BusStop(id: "BS48", name: "Collinare", location: CLLocationCoordinate2D(latitude: -6.2906680437956, longitude: 106.64538437301604)),
            BusStop(id: "BS49", name: "Foglio", location: CLLocationCoordinate2D(latitude: -6.293770702497992, longitude: 106.64307050539043)),
            BusStop(id: "BS50", name: "Studento 2", location: CLLocationCoordinate2D(latitude: -6.295336698270585, longitude: 106.642156093254)),
            BusStop(id: "BS51", name: "Albera", location: CLLocationCoordinate2D(latitude: -6.296627753866824, longitude: 106.64468911954826)),
            BusStop(id: "BS52", name: "Foresta 1", location: CLLocationCoordinate2D(latitude: -6.296720702463259, longitude: 106.647792186508)),
            BusStop(id: "BS53", name: "Simpang Foresta", location: CLLocationCoordinate2D(latitude: -6.299027376515015, longitude: 106.6479729112976)),
            BusStop(id: "BS54", name: "Allevare", location: CLLocationCoordinate2D(latitude: -6.297092109712094, longitude: 106.64701553315535)),
            BusStop(id: "BS55", name: "Fiore", location: CLLocationCoordinate2D(latitude: -6.296699551490208, longitude: 106.64459637983225)),
            BusStop(id: "BS56", name: "Studento 1", location: CLLocationCoordinate2D(latitude: -6.29562483743795, longitude: 106.64207466523365)),
            BusStop(id: "BS57", name: "Naturale", location: CLLocationCoordinate2D(latitude: -6.293753267157416, longitude: 106.64283525450247)),
            BusStop(id: "BS58", name: "Fresco", location: CLLocationCoordinate2D(latitude: -6.290917364823557, longitude: 106.64513283298477)),
            BusStop(id: "BS59", name: "Primavera", location: CLLocationCoordinate2D(latitude: -6.291167379758763, longitude: 106.64836291534402)),
            BusStop(id: "BS60", name: "Foresta 2", location: CLLocationCoordinate2D(latitude: -6.290166708825742, longitude: 106.64961926711759)),
            BusStop(id: "BS61", name: "FBL 5", location: CLLocationCoordinate2D(latitude: -6.28803670795394, longitude: 106.64433874198559)),
            BusStop(id: "BS62", name: "Courts Mega Store", location: CLLocationCoordinate2D(latitude: -6.286230035126002, longitude: 106.63887072883601)),
            BusStop(id: "BS63", name: "Q BIG 1", location: CLLocationCoordinate2D(latitude: -6.284470858067212, longitude: 106.63834676447388)),
            BusStop(id: "BS64", name: "Lulu", location: CLLocationCoordinate2D(latitude: -6.2806509823429675, longitude: 106.6363809368485)),
            BusStop(id: "BS65", name: "Greenwich Park 1", location: CLLocationCoordinate2D(latitude: -6.27722670353427, longitude: 106.63519582664144)),
            BusStop(id: "BS66", name: "Prestigia", location: CLLocationCoordinate2D(latitude: -6.294574704864883, longitude: 106.63434147612814)),
            BusStop(id: "BS67", name: "The Mozia 1", location: CLLocationCoordinate2D(latitude: -6.291653845052858, longitude: 106.62850019474901)),
            BusStop(id: "BS68", name: "Vanya Park", location: CLLocationCoordinate2D(latitude: -6.295320322717712, longitude: 106.62186825923906)),
            BusStop(id: "BS69", name: "Piazza Mozia", location: CLLocationCoordinate2D(latitude: -6.290512106223089, longitude: 106.62767242455752)),
            BusStop(id: "BS70", name: "The Mozia 2", location: CLLocationCoordinate2D(latitude: -6.291595339802968, longitude: 106.62865576632026)),
            BusStop(id: "BS71", name: "Illustria", location: CLLocationCoordinate2D(latitude: -6.294029293630429, longitude: 106.63433876241467)),
            BusStop(id: "BS72", name: "CBD Barat 2", location: CLLocationCoordinate2D(latitude: -6.3023066800188365, longitude: 106.64210145762934)),
            BusStop(id: "BS73", name: "Lobby AEON Mall", location: CLLocationCoordinate2D(latitude: -6.303683149161957, longitude: 106.64356012276883)),
            BusStop(id: "BS74", name: "CBD Utara 3", location: CLLocationCoordinate2D(latitude: -6.2987607030499175, longitude: 106.6433604073996)),
            BusStop(id: "BS75", name: "CBD Barat 1", location: CLLocationCoordinate2D(latitude: -6.299449375144083, longitude: 106.64191227244648)),
            BusStop(id: "BS76", name: "AEON Mall 2", location: CLLocationCoordinate2D(latitude: -6.302851368209015, longitude: 106.64431300128254)),
            BusStop(id: "BS77", name: "Froogy", location: CLLocationCoordinate2D(latitude: -6.29724016790295, longitude: 106.64050719580258)),
            BusStop(id: "BS78", name: "Gramedia", location: CLLocationCoordinate2D(latitude: -6.291269859841771, longitude: 106.6394645156416)),
            BusStop(id: "BS79", name: "Icon Centro", location: CLLocationCoordinate2D(latitude: -6.314595375739716, longitude: 106.646253224144)),
            BusStop(id: "BS80", name: "Horizon Broadway", location: CLLocationCoordinate2D(latitude: -6.313141392686883, longitude: 106.6503970845614)),
            BusStop(id: "BS81", name: "BSD Extreme Park", location: CLLocationCoordinate2D(latitude: -6.30975136988534, longitude: 106.6537962107912)),
            BusStop(id: "BS82", name: "Saveria", location: CLLocationCoordinate2D(latitude: -6.307346701354917, longitude: 106.65359854223301))
        ]
        
        // Initialize BSD Link routes
        self.bsdLinkRoutes = [
            BusRoute(id: "R01", name: "Intermoda - Sektor 1.3", stops: [bsdBusStops[0], bsdBusStops[4], bsdBusStops[5], bsdBusStops[6], bsdBusStops[12], bsdBusStops[13], bsdBusStops[14], bsdBusStops[15], bsdBusStops[16], bsdBusStops[18], bsdBusStops[21], bsdBusStops[22], bsdBusStops[23], bsdBusStops[24], bsdBusStops[25], bsdBusStops[26], bsdBusStops[27]], color: .route1),
            BusRoute(id: "R02", name: "Sektor 1.3 - Intermoda", stops: [bsdBusStops[27], bsdBusStops[28], bsdBusStops[29], bsdBusStops[30], bsdBusStops[31], bsdBusStops[32], bsdBusStops[33], bsdBusStops[34], bsdBusStops[35], bsdBusStops[14], bsdBusStops[15], bsdBusStops[16], bsdBusStops[39], bsdBusStops[0]], color: .route1),
            BusRoute(id: "R03", name: "Greenwich Park - Sektor 1.3", stops: [bsdBusStops[40], bsdBusStops[41], bsdBusStops[42], bsdBusStops[43], bsdBusStops[44], bsdBusStops[46], bsdBusStops[47], bsdBusStops[48], bsdBusStops[49], bsdBusStops[50], bsdBusStops[51], bsdBusStops[12], bsdBusStops[13], bsdBusStops[14], bsdBusStops[15], bsdBusStops[16], bsdBusStops[18], bsdBusStops[21], bsdBusStops[22], bsdBusStops[25], bsdBusStops[26], bsdBusStops[27]], color: .route2),
            BusRoute(id: "R04", name: "Sektor 1.3 - Greenwich Park", stops: [bsdBusStops[27], bsdBusStops[28], bsdBusStops[29], bsdBusStops[30], bsdBusStops[31], bsdBusStops[32], bsdBusStops[33], bsdBusStops[34], bsdBusStops[35], bsdBusStops[14], bsdBusStops[15], bsdBusStops[16], bsdBusStops[52], bsdBusStops[53], bsdBusStops[54], bsdBusStops[55], bsdBusStops[56], bsdBusStops[57], bsdBusStops[58], bsdBusStops[61], bsdBusStops[62], bsdBusStops[63], bsdBusStops[64], bsdBusStops[40]], color: .route2),
            BusRoute(id: "R05", name: "Intermoda - De Park (Rute 1)", stops: [bsdBusStops[0], bsdBusStops[4], bsdBusStops[5], bsdBusStops[6], bsdBusStops[7], bsdBusStops[11], bsdBusStops[76], bsdBusStops[77], bsdBusStops[61], bsdBusStops[62], bsdBusStops[63], bsdBusStops[64], bsdBusStops[40], bsdBusStops[41], bsdBusStops[42], bsdBusStops[43], bsdBusStops[44]], color: .route3),
            BusRoute(id: "R06", name: "Intermoda - De Park (Rute 2)", stops: [bsdBusStops[0], bsdBusStops[78], bsdBusStops[79], bsdBusStops[80], bsdBusStops[81], bsdBusStops[13], bsdBusStops[14], bsdBusStops[15], bsdBusStops[37], bsdBusStops[75], bsdBusStops[16], bsdBusStops[52], bsdBusStops[53], bsdBusStops[54], bsdBusStops[55], bsdBusStops[56], bsdBusStops[57], bsdBusStops[58], bsdBusStops[59], bsdBusStops[44]], color: .route4),
            BusRoute(id: "R07", name: "The Breeze - AEON - ICE - The Breeze", stops: [bsdBusStops[14], bsdBusStops[15], bsdBusStops[16], bsdBusStops[73], bsdBusStops[74], bsdBusStops[71], bsdBusStops[37], bsdBusStops[75], bsdBusStops[73], bsdBusStops[9], bsdBusStops[11], bsdBusStops[74], bsdBusStops[71], bsdBusStops[37], bsdBusStops[75], bsdBusStops[16], bsdBusStops[18], bsdBusStops[36], bsdBusStops[14]], color: .route5),
            BusRoute(id: "R08", name: "Intermoda - Vanya Park - Intermoda", stops: [bsdBusStops[0], bsdBusStops[2], bsdBusStops[3], bsdBusStops[4], bsdBusStops[47], bsdBusStops[48], bsdBusStops[49], bsdBusStops[50], bsdBusStops[66], bsdBusStops[44], bsdBusStops[45], bsdBusStops[46], bsdBusStops[67], bsdBusStops[68], bsdBusStops[69], bsdBusStops[70], bsdBusStops[71], bsdBusStops[5], bsdBusStops[6], bsdBusStops[7], bsdBusStops[72], bsdBusStops[73], bsdBusStops[54], bsdBusStops[74], bsdBusStops[8], bsdBusStops[55], bsdBusStops[56], bsdBusStops[60], bsdBusStops[61], bsdBusStops[62], bsdBusStops[1], bsdBusStops[0]], color: .route6)
        ]
        
        super.init()
    }
    func colorForRoute(_ route: BusRoute) -> Color {
        return Color(route.color)
    }
    
    func findNearbyStops(to coordinate: CLLocationCoordinate2D, maxDistance: Double = 500) -> [BusStop] {
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return bsdBusStops.filter { stop in
            let stopLocation = CLLocation(latitude: stop.location.latitude, longitude: stop.location.longitude)
            let distance = stopLocation.distance(from: userLocation)
            return distance <= maxDistance
        }
    }
    
    func findRouteOptions(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        suggestedRoutes.removeAll()
        showBusStops = false
        showDrivingRoute = true
        visibleBusStops = []
        
        // Get driving route for overview
        getDrivingRoute(from: start, to: end) { polyline in
            DispatchQueue.main.async {
                self.drivingRoute = polyline
            }
        }
        
        let startStops = findNearbyStops(to: start)
        let endStops = findNearbyStops(to: end)
        
        for startStop in startStops {
            for endStop in endStops {
                // Filter routes that contain both stops AND allow the direction
                let validRoutes = bsdLinkRoutes.filter { route in
                    guard let startIndex = route.stops.firstIndex(where: { $0.id == startStop.id }),
                          let endIndex = route.stops.firstIndex(where: { $0.id == endStop.id })
                    else { return false }
                    
                    // Only allow routes where start comes BEFORE end (one-way)
                    return startIndex <= endIndex
                }
                
                for route in validRoutes {
                    guard let startIndex = route.stops.firstIndex(where: { $0.id == startStop.id }),
                          let endIndex = route.stops.firstIndex(where: { $0.id == endStop.id })
                    else { continue }
                    
                    let walkingTimeToStart = calculateWalkingTime(from: start, to: startStop.location)
                    let stopCount = endIndex - startIndex // No abs() since direction is enforced
                    let busTravelTime = TimeInterval(stopCount * 3 * 60)
                    let walkingTimeToDestination = calculateWalkingTime(from: endStop.location, to: end)
                    let totalTime = walkingTimeToStart + busTravelTime + walkingTimeToDestination
                    
                    // Generate schedules
                    let schedules: [String] = {
                        var times = [String]()

                        for hour in 14..<16 {
                                times.append(String(format: "%02d:17", hour))
                                times.append(String(format: "%02d:37", hour))
                                times.append(String(format: "%02d:57", hour))
                            }
                        for hour in 16..<19 {
                                times.append(String(format: "%02d:04", hour))
                                times.append(String(format: "%02d:24", hour))
                                times.append(String(format: "%02d:54", hour))
                                times.append(String(format: "%02d:59", hour))
                            }
                        for hour in 19..<20 {
                                times.append(String(format: "%02d:10", hour))
                                times.append(String(format: "%02d:30", hour))
                            }
                            
                            return times
                    }()
                    
                    let suggestedRoute = SuggestedRoute(
                        route: route,
                        startStop: startStop,
                        endStop: endStop,
                        walkingTimeToStart: walkingTimeToStart,
                        busTravelTime: busTravelTime,
                        walkingTimeToDestination: walkingTimeToDestination,
                        totalTime: totalTime,
                        schedules: schedules
                    )
                    
                    suggestedRoutes.append(suggestedRoute)
                }
            }
        }
        
        // Sort by fastest total time
        suggestedRoutes.sort { $0.totalTime < $1.totalTime }
        
        // Optional: Show warning if no routes found
        if suggestedRoutes.isEmpty {
            print("No valid routes found. Try different start/end points.")
        }
    }
    
    func planSpecificRoute(_ suggestedRoute: SuggestedRoute, from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        currentRoute = suggestedRoute.route
        currentRouteColor = Color(suggestedRoute.route.color)
        routes.removeAll()
        routeSteps.removeAll()
        showBusStops = true
        showDrivingRoute = false
        
        // Get only the stops between start and end stops
        let relevantStops = suggestedRoute.route.stopsBetween(start: suggestedRoute.startStop, end: suggestedRoute.endStop)
        visibleBusStops = relevantStops
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        let now = Date()
        var accumulatedTime: TimeInterval = 0
        
        let startStep = RouteStep(
            time: dateFormatter.string(from: now),
            location: "Start Point",
            address: nil,
            duration: nil,
            transportType: .walk,
            stops: nil,
            coordinate: start
        )
        routeSteps.append(startStep)
        
        getWalkingRoute(from: start, to: suggestedRoute.startStop.location) { walkRoute in
            DispatchQueue.main.async {
                self.routes.append(walkRoute.polyline)
                
                let walkStep = RouteStep(
                    time: dateFormatter.string(from: Calendar.current.date(byAdding: .second, value: Int(accumulatedTime), to: now)!),
                    location: "Walk to \(suggestedRoute.startStop.name)",
                    address: nil,
                    duration: self.formattedDuration(suggestedRoute.walkingTimeToStart),
                    transportType: .walk,
                    stops: nil,
                    coordinate: suggestedRoute.startStop.location
                )
                self.routeSteps.append(walkStep)
                accumulatedTime += suggestedRoute.walkingTimeToStart
                
                self.getDrivingRoute(from: suggestedRoute.startStop.location, to: suggestedRoute.endStop.location) { busPolyline in
                    DispatchQueue.main.async {
                        self.routes.append(busPolyline)
                        
                        // Only show the relevant stops in the route step
                        let busStep = RouteStep(
                            time: dateFormatter.string(from: Calendar.current.date(byAdding: .second, value: Int(accumulatedTime), to: now)!),
                            location: "Take \(suggestedRoute.route.name)",
                            address: nil,
                            duration: self.formattedDuration(suggestedRoute.busTravelTime),
                            transportType: .bus,
                            stops: relevantStops.map { $0.name },  // Only relevant stops
                            coordinate: suggestedRoute.endStop.location
                        )
                        self.routeSteps.append(busStep)
                        accumulatedTime += suggestedRoute.busTravelTime
                        
                        self.getWalkingRoute(from: suggestedRoute.endStop.location, to: end) { finalWalk in
                            DispatchQueue.main.async {
                                self.routes.append(finalWalk.polyline)
                                
                                let finalStep = RouteStep(
                                    time: dateFormatter.string(from: Calendar.current.date(byAdding: .second, value: Int(accumulatedTime), to: now)!),
                                    location: "Walk to Destination",
                                    address: nil,
                                    duration: self.formattedDuration(suggestedRoute.walkingTimeToDestination),
                                    transportType: .walk,
                                    stops: nil,
                                    coordinate: end
                                )
                                self.routeSteps.append(finalStep)
                                accumulatedTime += suggestedRoute.walkingTimeToDestination
                                
                                let destinationStep = RouteStep(
                                    time: dateFormatter.string(from: Calendar.current.date(byAdding: .second, value: Int(accumulatedTime), to: now)!),
                                    location: "Destination",
                                    address: nil,
                                    duration: nil,
                                    transportType: .destination,
                                    stops: nil,
                                    coordinate: end
                                )
                                self.routeSteps.append(destinationStep)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func clearRouteDetails() {
        routes.removeAll()
        routeSteps.removeAll()
        showBusStops = false
        visibleBusStops = []
    }
    
    private func calculateWalkingTime(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> TimeInterval {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distance = fromLocation.distance(from: toLocation)
        return (distance / 80) * 60
    }
    
    private func getDrivingRoute(from: CLLocationCoordinate2D,
                              to: CLLocationCoordinate2D,
                              completion: @escaping (MKPolyline) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .automobile
        
        MKDirections(request: request).calculate { response, error in
            if let route = response?.routes.first {
                completion(route.polyline)
            } else {
                let coordinates = [from, to]
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                completion(polyline)
            }
        }
    }
    
    private func getWalkingRoute(from: CLLocationCoordinate2D,
                               to: CLLocationCoordinate2D,
                               completion: @escaping (MKRoute) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .walking
        
        MKDirections(request: request).calculate { response, _ in
            if let route = response?.routes.first {
                completion(route)
            }
        }
    }
    
    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: seconds) ?? ""
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var routePlanner = RoutePlanner()
    @State private var position = MapCameraPosition.automatic
    @State private var initialRegionSet = false
    @State private var startSearchText = ""
    @State private var endSearchText = ""
    @State private var startSearchResults: [MKMapItem] = []
    @State private var endSearchResults: [MKMapItem] = []
    @State private var showStartSearchResults = false
    @State private var showEndSearchResults = false
    @State private var startCoordinate: CLLocationCoordinate2D?
    @State private var endCoordinate: CLLocationCoordinate2D?
    @State private var showRouteSheet = false
    @State private var showingRouteSteps = false
    @FocusState private var focusedField: SearchField?

        enum SearchField {
            case start, end
        }
    
    private let locationManager = CLLocationManager()
    
    var body: some View {
        NavigationStack {
                ZStack(alignment: .top) {
                    Map(position: $position, interactionModes: .all) {
                        // Start Marker
                        if let startCoordinate = startSearchResults.first?.placemark.coordinate {
                            Annotation("Start", coordinate: startCoordinate) {
                                ZStack {
                                    Circle()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.green)
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        // End Marker
                        if let endCoordinate = endSearchResults.first?.placemark.coordinate {
                            Annotation("Destination", coordinate: endCoordinate) {
                                ZStack {
                                    Circle()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.blue)
                                    Image(systemName: "mappin")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        // Driving route (shown when viewing suggested routes)
                        if let drivingRoute = routePlanner.drivingRoute, routePlanner.showDrivingRoute {
                            MapPolyline(drivingRoute)
                                .stroke(.blue, lineWidth: 3)
                        }
                        
                        // Bus stops (only shown when viewing specific route)
                        if routePlanner.showBusStops {
                            ForEach(routePlanner.visibleBusStops) { stop in
                                Annotation(stop.name, coordinate: stop.location) {
                                    ZStack {
                                        Circle()
                                            .frame(width: 16, height: 16)
                                            .foregroundColor(.red)
                                        Image(systemName: "bus")
                                            .font(.system(size: 8))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        
                        // Route Lines
                        ForEach(routePlanner.routes.indices, id: \.self) { index in
                            let route = routePlanner.routes[index]
                            let isWalking = index == 0 || index == routePlanner.routes.count - 1
                            
                            // Get the color based on the route
                            let routeColor: Color = {
                                if isWalking {
                                    return .blue // Walking routes are always blue
                                } else {
                                    return routePlanner.currentRouteColor
                                }
                            }()
                            
                            MapPolyline(route)
                                .stroke(
                                    routeColor,
                                    style: StrokeStyle(
                                        lineWidth: 4,
                                        lineCap: .round,
                                        lineJoin: .round,
                                        dash: isWalking ? [10, 10] : []
                                    )
                                )
                        }
                    }
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }
                    .onAppear {
                        if !initialRegionSet {
                            let tangerangCenter = CLLocationCoordinate2D(latitude: -6.1781, longitude: 106.6319)
                            let region = MKCoordinateRegion(
                                center: tangerangCenter,
                                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                            )
                            position = .region(region)
                            initialRegionSet = true
                        }
                        locationManager.requestWhenInUseAuthorization()
                    }.mapControls{
                        MapCompass()
                        MapScaleView()
                    }
                    .ignoresSafeArea()
                    
                    // Search Bars with performSearch and reverse button
                    VStack(spacing: 16) {
                        // Start Location Search Bar
                        HStack {
                            TextField("Your Location", text: Binding(
                                get: { startSearchText },
                                set: { newValue in
                                    startSearchText = newValue
                                    if !newValue.isEmpty {
                                        performSearch(query: newValue, isStart: true)
                                        showStartSearchResults = true
                                    } else {
                                        startSearchResults = []
                                        showStartSearchResults = false
                                    }
                                }
                            ))
                            .focused($focusedField, equals: .start)
                            .autocapitalization(.none)
                        }
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        // End Location Search Bar
                        HStack {
                            TextField("Where to?", text: Binding(
                                get: { endSearchText },
                                set: { newValue in
                                    endSearchText = newValue
                                    if !newValue.isEmpty {
                                        performSearch(query: newValue, isStart: false)
                                        showEndSearchResults = true
                                    } else {
                                        endSearchResults = []
                                        showEndSearchResults = false
                                    }
                                }
                            ))
                            .focused($focusedField, equals: .end)
                            .autocapitalization(.none)
                        }
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        // Reverse Button
                        HStack {
                            Spacer().frame(height: 40)
                            Button(action: reverseLocations) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .frame(width: 30, height: 40)
                                    .font(.system(size: 18))
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Rectangle())
                                    .cornerRadius(8)
                            }
                            .padding(.trailing, 32)
                            .offset(y:-88)
                        }
                        
                    }
                    .padding(.top, 8)
                    
                    if showStartSearchResults && !startSearchResults.isEmpty {
                        List(startSearchResults, id: \.self) { item in
                            VStack(alignment: .leading) {
                                Text(item.name ?? "Unknown")
                                Text(item.placemark.title ?? "")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .onTapGesture {
                                selectLocation(item: item, isStart: true)
                                focusedField = nil
                                showStartSearchResults = false
                            }
                        }
                        .listStyle(.plain)
                        .frame(height: 200)
                        .padding(.horizontal)
                        .offset(y: 60)
                    }
                    
                    if showEndSearchResults && !endSearchResults.isEmpty {
                        List(endSearchResults, id: \.self) { item in
                            VStack(alignment: .leading) {
                                Text(item.name ?? "Unknown")
                                Text(item.placemark.title ?? "")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .onTapGesture {
                                selectLocation(item: item, isStart: false)
                                focusedField = nil
                                showEndSearchResults = false
                            }
                        }
                        .listStyle(.plain)
                        .frame(height: 200)
                        .padding(.horizontal)
                        .offset(y: 120)
                    }
                    // Map Route Button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            NavigationLink {
                                SimpleRouteView()
                            } label: {
                                Image(systemName: "bus.doubledecker.fill")
                                    .frame(width: 80, height: 80)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .cornerRadius(8)
                                    .foregroundColor(.blue)
                                    .font(.system(size: 30))
                            }
                            .padding(20)
                        }
                       
                    }
                }
                .sheet(isPresented: $showRouteSheet) {
                    if showingRouteSteps {
                        RouteStepsView(
                            routeSteps: routePlanner.routeSteps,
                            onBack: {
                                routePlanner.clearRouteDetails()
                                showingRouteSteps = false
                            }
                        )
                        .interactiveDismissDisabled()
                        .presentationDetents([.height(200), .medium, .large])
                        .presentationBackgroundInteraction(.enabled(upThrough: .large))
                        .presentationCornerRadius(16)
                        .presentationDragIndicator(.visible)
                    } else {
                        SuggestedRoutesView(
                            suggestedRoutes: $routePlanner.suggestedRoutes,
                            onRouteSelected: { suggestedRoute in
                                if let start = startCoordinate, let end = endCoordinate {
                                    routePlanner.planSpecificRoute(suggestedRoute, from: start, to: end)
                                    showingRouteSteps = true
                                }
                            }, onClose: {
                                    showRouteSheet = false
                                    startSearchText = ""
                                    endSearchText = ""
                                    startSearchResults = []
                                    endSearchResults = []
                                    startCoordinate = nil
                                    endCoordinate = nil
                                    routePlanner.clearRouteDetails()
                            }
                        )
                        .interactiveDismissDisabled()
                        .presentationDetents([.height(200), .medium, .large])
                        .presentationBackgroundInteraction(.enabled(upThrough: .large))
                        .presentationCornerRadius(16)
                        .presentationDragIndicator(.visible)
                    }
                }.onAppear {
                    locationManager.requestWhenInUseAuthorization()
                    
                }
                .toolbarBackgroundVisibility(.hidden)
        }

    }
    
    private func reverseLocations() {
            // Temporarily disable search updates
            let oldStartText = startSearchText
            let oldEndText = endSearchText
            
            // Swap the values without triggering onChange
            startSearchText = oldEndText
            endSearchText = oldStartText
            
            // Swap the results
            let tempResults = startSearchResults
            startSearchResults = endSearchResults
            endSearchResults = tempResults
            
            // Hide any visible search results
            showStartSearchResults = false
            showEndSearchResults = false
            
            if !startSearchResults.isEmpty && !endSearchResults.isEmpty {
                startCoordinate = startSearchResults.first!.placemark.coordinate
                            endCoordinate = endSearchResults.first!.placemark.coordinate
                            routePlanner.findRouteOptions(from: startCoordinate!, to: endCoordinate!)
                            showRouteSheet = true
                            showingRouteSteps = false
                            updateCameraPosition()
            }
        }
    
    private func performSearch(query: String, isStart: Bool) {
        guard !query.isEmpty else {
            if isStart {
                startSearchResults = []
                showStartSearchResults = false
            } else {
                endSearchResults = []
                showEndSearchResults = false
            }
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        
        let tangerangCenter = CLLocationCoordinate2D(latitude: -6.1781, longitude: 106.6319)
        let region = MKCoordinateRegion(
            center: tangerangCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
        
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("Error searching: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let filteredResults = response.mapItems.filter { item in
                if let locality = item.placemark.locality {
                    return locality.lowercased().contains("tangerang")
                }
                return false
            }
            
            if isStart {
                startSearchResults = filteredResults
                showStartSearchResults = true
            } else {
                endSearchResults = filteredResults
                showEndSearchResults = true
            }
        }
    }
    
    private func selectLocation(item: MKMapItem, isStart: Bool) {
        if isStart {
            startSearchText = item.name ?? "Unknown location"
            startSearchResults = [item]
            showStartSearchResults = false
        } else {
            endSearchText = item.name ?? "Unknown location"
            endSearchResults = [item]
            showEndSearchResults = false
        }
        
        if !startSearchResults.isEmpty && !endSearchResults.isEmpty {
            startCoordinate = startSearchResults.first!.placemark.coordinate
            endCoordinate = endSearchResults.first!.placemark.coordinate
            routePlanner.findRouteOptions(from: startCoordinate!, to: endCoordinate!)
            showRouteSheet = true
            showingRouteSteps = false
            updateCameraPosition()
        }
    }
    
    private func updateCameraPosition() {
        guard let startCoordinate = startCoordinate,
              let endCoordinate = endCoordinate else {
            return
        }

        let centerLatitude = (startCoordinate.latitude + endCoordinate.latitude) / 2
        let centerLongitude = (startCoordinate.longitude + endCoordinate.longitude) / 2
        
        let latitudeDelta = abs(startCoordinate.latitude - endCoordinate.latitude) * 2.5
        let longitudeDelta = abs(startCoordinate.longitude - endCoordinate.longitude) * 2.5

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
            span: MKCoordinateSpan(latitudeDelta: max(latitudeDelta, 0.01), longitudeDelta: max(longitudeDelta, 0.01))
        )

        DispatchQueue.main.async {
            withAnimation {
                position = .region(region)
            }
        }
    }
}

// MARK: - Suggested Routes View
struct SuggestedRoutesView: View {
    @Binding var suggestedRoutes: [SuggestedRoute]
    var onRouteSelected: (SuggestedRoute) -> Void
    var onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Sticky header
            VStack(alignment: .leading) {
                HStack {
                    Text("Suggested Routes")
                        .font(.title2.bold())
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Content area
                if suggestedRoutes.isEmpty {
                    VStack {
                        Spacer()
                        Text("No routes found between these locations")
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground)) // Or your preferred background color
                } else {
                    
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 12) {
                            ForEach(suggestedRoutes) { suggestedRoute in
                                SuggestedRouteCard(
                                    suggestedRoute: suggestedRoute,
                                    onSelect: { onRouteSelected(suggestedRoute) }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    }
                    .background(Color(.systemBackground)) // Ensures consistent background
                }
            }
            .background(Color(.systemBackground)) // Full sheet background
            .edgesIgnoringSafeArea(.bottom) // Makes sure color goes all the way down
        }
    }
}

struct SuggestedRouteCard: View {
    let suggestedRoute: SuggestedRoute
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(Color(suggestedRoute.route.color))
                        .frame(width: 16, height: 16)
                    
                    Text(suggestedRoute.route.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(suggestedRoute.formattedTotalTime)
                        .font(.subheadline.bold())
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("From:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(suggestedRoute.startStop.name)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("To:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(suggestedRoute.endStop.name)
                            .font(.subheadline)
                    }
                }
                
                Divider()
                
                Text("Next Departures:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestedRoute.schedules.prefix(8), id: \.self) { schedule in
                            Text(schedule)
                                .font(.caption)
                                .padding(6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Route Steps View
struct RouteStepsView: View {
    let routeSteps: [RouteStep]
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Header (just back button)
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17).bold())
                        Text("Back")
                            .font(.subheadline)
                    }
                    .foregroundColor(.blue)
                }
                .padding(.leading, 16)
                .padding(.vertical, 12)
                
                Spacer()
            }
            .background(Color(.systemBackground))
            
            // Route Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // "Your Route" section header
                    Text("Your Route")
                        .font(.title3.bold())
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Route Steps
                    VStack(alignment: .leading, spacing: -15) {
                        if routeSteps.isEmpty {
                            Text("No route steps available")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(routeSteps.indices, id: \.self) { index in
                                let step = routeSteps[index]
                                let isLast = index == routeSteps.count - 1
                                
                                HStack(alignment: .top, spacing: 12) {
                                    // Time column
                                    Text(step.time)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    // Timeline column
                                    VStack(spacing: 0) {
                                        // Circle for the current step
                                        ZStack {
                                            Circle()
                                                .frame(width: 20, height: 20)
                                                .foregroundColor(backgroundColor(for: step.transportType))
                                            
                                            transportIcon(for: step.transportType)
                                                .font(.system(size: 10))
                                                .foregroundColor(.white)
                                        }
                                        
                                        // Vertical line connecting to next step (if not last)
                                        if !isLast {
                                            Rectangle()
                                                .frame(width: 2, height: 100)
                                                .foregroundColor(lineColor(for: step.transportType))
                                        }
                                    }
                                    .frame(width: 20)
                                    
                                    // Details column
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(step.location)
                                            .font(.headline)
                                        
                                        if let address = step.address {
                                            Text(address)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        if let duration = step.duration {
                                            Text(duration)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        if let stops = step.stops {
                                            ForEach(stops, id: \.self) { stop in
                                                Text("· \(stop)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    // Helper methods remain the same...
    private func transportIcon(for type: RouteStep.TransportType) -> some View {
        switch type {
        case .walk: return Image(systemName: "figure.walk")
        case .bus: return Image(systemName: "bus")
        case .destination: return Image(systemName: "mappin")
        }
    }
    
    private func backgroundColor(for type: RouteStep.TransportType) -> Color {
        switch type {
        case .walk: return .green
        case .bus: return .red
        case .destination: return .blue
        }
    }
    
    private func lineColor(for type: RouteStep.TransportType) -> Color {
        switch type {
        case .walk: return .green.opacity(0.5)
        case .bus: return .red.opacity(0.5)
        case .destination: return .clear
        }
    }
}

#Preview {
    ContentView()
}
