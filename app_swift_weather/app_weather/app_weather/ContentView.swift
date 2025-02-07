//
//  ContentView.swift
//  app_weather
//
//  Created by Ritesh Mahara on 07/02/25.
//

import SwiftUI
import CoreLocation

// MARK: - Weather API Models
struct WeatherResponse: Codable {
    let name: String
    let sys: Sys
    let main: Main
    let weather: [Weather]
    let wind: Wind
    
    struct Sys: Codable { let country: String }
    struct Main: Codable { let temp: Double; let humidity: Int }
    struct Weather: Codable { let description: String; let icon: String }
    struct Wind: Codable { let speed: Double }
}

struct ForecastResponse: Codable {
    let list: [Forecast]
    
    struct Forecast: Codable {
        let dt: Int
        let main: Main
        let weather: [Weather]
        
        struct Main: Codable { let temp: Double }
        struct Weather: Codable { let icon: String }
    }
}

// MARK: - ViewModel for Weather Data
class WeatherViewModel: ObservableObject {
    @Published var city: String = "Enter city..."
    @Published var temperature: String = "--°C"
    @Published var description: String = "Weather description"
    @Published var humidity: String = "--%"
    @Published var windSpeed: String = "-- m/s"
    @Published var icon: String = "sun.max"
    @Published var forecasts: [ForecastResponse.Forecast] = []
    
    let apiKey = "ad574d500e8afe03c826bee2296669ad" // Your OpenWeather API Key
    
    func fetchWeather(city: String) {
        let weatherURL = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=metric"
        
        URLSession.shared.dataTask(with: URL(string: weatherURL)!) { data, _, _ in
            if let data = data {
                if let response = try? JSONDecoder().decode(WeatherResponse.self, from: data) {
                    DispatchQueue.main.async {
                        self.city = "\(response.name), \(response.sys.country)"
                        self.temperature = "\(String(format: "%.1f", response.main.temp))°C"
                        self.description = response.weather.first?.description ?? "Unknown"
                        self.humidity = "💧 \(response.main.humidity)%"
                        self.windSpeed = "🌬 \(response.wind.speed) m/s"
                        self.icon = response.weather.first?.icon ?? "sun.max"
                    }
                }
            }
        }.resume()
        
        fetchForecast(city: city)
    }
    
    func fetchForecast(city: String) {
        let forecastURL = "https://api.openweathermap.org/data/2.5/forecast?q=\(city)&appid=\(apiKey)&units=metric"
        
        URLSession.shared.dataTask(with: URL(string: forecastURL)!) { data, _, _ in
            if let data = data {
                if let response = try? JSONDecoder().decode(ForecastResponse.self, from: data) {
                    DispatchQueue.main.async {
                        self.forecasts = Array(response.list.prefix(5))
                    }
                }
            }
        }.resume()
    }
}

// MARK: - Main UI
struct ContentView: View {
    @StateObject var viewModel = WeatherViewModel()
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 20) {
                Text("🌤 Weather Pulse")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 3)
                
                // Search Bar
                HStack {
                    TextField("Enter city...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                    
                    Button(action: {
                        viewModel.fetchWeather(city: searchText)
                    }) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                
                // Weather Info Card
                VStack(spacing: 10) {
                    Text(viewModel.city)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                    
                    Image(systemName: getWeatherIcon(iconCode: viewModel.icon))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.yellow)
                    
                    Text(viewModel.temperature)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                    
                    Text(viewModel.description.capitalized)
                        .foregroundColor(.white)
                        .font(.title3)
                    
                    HStack {
                        Text(viewModel.windSpeed)
                        Text(viewModel.humidity)
                    }
                    .foregroundColor(.white)
                    .font(.body)
                }
                .padding()
                .background(glassBackground)
                .cornerRadius(20)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                // Forecast Section
                Text("5-Day Forecast")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(viewModel.forecasts, id: \.dt) { forecast in
                            VStack {
                                Text(formatDate(timestamp: forecast.dt))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Image(systemName: getWeatherIcon(iconCode: forecast.weather.first?.icon ?? ""))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.yellow)
                                
                                Text("\(String(format: "%.1f", forecast.main.temp))°C")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(glassBackground)
                            .cornerRadius(15)
                            .shadow(radius: 3)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var glassBackground: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color.white.opacity(0.3))
            .blur(radius: 10)
    }
    
    func formatDate(timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    func getWeatherIcon(iconCode: String) -> String {
        switch iconCode {
        case "01d", "01n": return "sun.max.fill"
        case "02d", "02n": return "cloud.sun.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d", "10n": return "cloud.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snowflake"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "questionmark"
        }
    }
}

// MARK: - App Entry Point
@main
struct WeatherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
