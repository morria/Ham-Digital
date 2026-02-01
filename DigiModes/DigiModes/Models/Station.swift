//
//  Station.swift
//  DigiModes
//

import Foundation

struct Station: Identifiable {
    let id: UUID
    var callsign: String
    var name: String
    var qth: String  // Location
    var grid: String // Maidenhead grid square

    init(
        id: UUID = UUID(),
        callsign: String = "",
        name: String = "",
        qth: String = "",
        grid: String = ""
    ) {
        self.id = id
        self.callsign = callsign
        self.name = name
        self.qth = qth
        self.grid = grid
    }

    static let myStation = Station(
        callsign: "N0CALL",
        name: "Your Name",
        qth: "Your City, ST",
        grid: "DM79"
    )
}
