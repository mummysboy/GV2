//
//  LocationService.swift
//  Gig
//
//  Created by Isaac Hirsch on 7/9/25.
//

import Foundation

class LocationService {
    static let shared = LocationService()
    
    // Mock location data for development
    private let mockLocations = [
        "San Francisco, CA",
        "Los Angeles, CA", 
        "New York, NY",
        "Chicago, IL",
        "Houston, TX",
        "Phoenix, AZ",
        "Philadelphia, PA",
        "San Antonio, TX",
        "San Diego, CA",
        "Dallas, TX",
        "Austin, TX",
        "Jacksonville, FL",
        "Fort Worth, TX",
        "Columbus, OH",
        "Charlotte, NC",
        "San Jose, CA",
        "Indianapolis, IN",
        "Seattle, WA",
        "Denver, CO",
        "Washington, DC",
        "Boston, MA",
        "El Paso, TX",
        "Nashville, TN",
        "Detroit, MI",
        "Oklahoma City, OK",
        "Portland, OR",
        "Las Vegas, NV",
        "Memphis, TN",
        "Louisville, KY",
        "Baltimore, MD",
        "Milwaukee, WI",
        "Albuquerque, NM",
        "Tucson, AZ",
        "Fresno, CA",
        "Sacramento, CA",
        "Mesa, AZ",
        "Kansas City, MO",
        "Atlanta, GA",
        "Long Beach, CA",
        "Colorado Springs, CO",
        "Raleigh, NC",
        "Miami, FL",
        "Virginia Beach, VA",
        "Omaha, NE",
        "Oakland, CA",
        "Minneapolis, MN",
        "Tampa, FL",
        "Tulsa, OK",
        "Arlington, TX",
        "New Orleans, LA",
        "Wichita, KS",
        "Cleveland, OH",
        "Bakersfield, CA",
        "Aurora, CO",
        "Anaheim, CA",
        "Honolulu, HI",
        "Santa Ana, CA",
        "Corpus Christi, TX",
        "Riverside, CA",
        "Lexington, KY",
        "Stockton, CA",
        "Henderson, NV",
        "Saint Paul, MN",
        "St. Louis, MO",
        "Fort Wayne, IN",
        "Jersey City, NJ",
        "Chandler, AZ",
        "Madison, WI",
        "Lubbock, TX",
        "Scottsdale, AZ",
        "Reno, NV",
        "Buffalo, NY",
        "Gilbert, AZ",
        "Glendale, AZ",
        "North Las Vegas, NV",
        "Winston-Salem, NC",
        "Chesapeake, VA",
        "Norfolk, VA",
        "Fremont, CA",
        "Garland, TX",
        "Irving, TX",
        "Hialeah, FL",
        "Richmond, VA",
        "Boise, ID",
        "Spokane, WA",
        "Baton Rouge, LA"
    ]
    
    private init() {}
    
    func autocomplete(_ query: String, completion: @escaping ([String]) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let filteredLocations = self.mockLocations.filter { location in
                location.lowercased().contains(query.lowercased())
            }
            
            // Limit results to top 10
            let results = Array(filteredLocations.prefix(10))
            completion(results)
        }
    }
    
    func validateLocation(_ location: String, completion: @escaping (Bool) -> Void) {
        // For now, just check if it's not empty and has a comma
        let isValid = !location.isEmpty && location.contains(",")
        completion(isValid)
    }
} 