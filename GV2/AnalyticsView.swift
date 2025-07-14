import SwiftUI
import CoreData
import Charts

struct AnalyticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Gig.createdAt, ascending: false)],
        animation: .default)
    private var allGigs: FetchedResults<Gig>
    
    // Add computed property to filter gigs for current user
    private var userGigs: [Gig] {
        let currentUser = AnalyticsView.currentUser(in: viewContext)
        return allGigs.filter { $0.provider == currentUser }
    }
    
    @State private var selectedTimeRange = "Last 7 Days"
    @State private var selectedGig: Gig?
    
    let timeRanges = ["Last 7 Days", "Last 30 Days", "Last 90 Days", "All Time"]
    
    // Sample analytics data - in a real app, this would come from a backend
    var analyticsData: AnalyticsData {
        AnalyticsData(
            totalViews: Int.random(in: 1000...5000),
            totalImpressions: Int.random(in: 5000...15000),
            totalMessages: Int.random(in: 50...200),
            totalBookings: Int.random(in: 10...50),
            clickThroughRate: Double.random(in: 0.05...0.15),
            conversionRate: Double.random(in: 0.02...0.08),
            averageResponseTime: Int.random(in: 2...24),
            topPerformingGigs: Array(userGigs.prefix(3)),
            weeklyData: generateWeeklyData(),
            categoryPerformance: generateCategoryPerformance()
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with time range selector
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Analytics & Insights")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Track your gig performance")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Picker("Time Range", selection: $selectedTimeRange) {
                                ForEach(timeRanges, id: \.self) { range in
                                    Text(range).tag(range)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.appGrayLight)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Key Metrics Overview
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        MetricCard(
                            title: "Total Views",
                            value: "\(analyticsData.totalViews)",
                            change: "+12%",
                            isPositive: true,
                            icon: "eye.fill",
                            color: .blue
                        )
                        
                        MetricCard(
                            title: "Total Impressions",
                            value: "\(analyticsData.totalImpressions)",
                            change: "+8%",
                            isPositive: true,
                            icon: "chart.bar.fill",
                            color: .green
                        )
                        
                        MetricCard(
                            title: "Messages",
                            value: "\(analyticsData.totalMessages)",
                            change: "+15%",
                            isPositive: true,
                            icon: "message.fill",
                            color: .purple
                        )
                        
                        MetricCard(
                            title: "Bookings",
                            value: "\(analyticsData.totalBookings)",
                            change: "+5%",
                            isPositive: true,
                            icon: "calendar.badge.plus",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Performance Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Performance Over Time")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        PerformanceChart(data: analyticsData.weeklyData)
                            .frame(height: 200)
                            .padding(.horizontal)
                    }
                    
                    // Conversion Metrics
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Conversion Metrics")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ConversionMetricRow(
                                title: "Click-Through Rate",
                                value: String(format: "%.1f%%", analyticsData.clickThroughRate * 100),
                                description: "Views to clicks ratio"
                            )
                            
                            ConversionMetricRow(
                                title: "Conversion Rate",
                                value: String(format: "%.1f%%", analyticsData.conversionRate * 100),
                                description: "Clicks to bookings ratio"
                            )
                            
                            ConversionMetricRow(
                                title: "Avg Response Time",
                                value: "\(analyticsData.averageResponseTime)h",
                                description: "Time to respond to messages"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Top Performing Gigs
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Top Performing Gigs")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(analyticsData.topPerformingGigs.enumerated()), id: \.element.id) { index, gig in
                                    TopGigCard(
                                        gig: gig,
                                        rank: index + 1,
                                        views: Int.random(in: 200...800),
                                        bookings: Int.random(in: 5...20)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Category Performance
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Category Performance")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(analyticsData.categoryPerformance, id: \.category) { performance in
                                CategoryPerformanceRow(performance: performance)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Insights and Recommendations
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Insights & Recommendations")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            InsightCard(
                                title: "Peak Activity Times",
                                description: "Your gigs get the most views between 6-8 PM. Consider posting updates during these hours.",
                                icon: "clock.fill",
                                color: .blue
                            )
                            
                            InsightCard(
                                title: "High-Converting Categories",
                                description: "Pet Care and Tutoring gigs have 40% higher conversion rates. Consider expanding in these areas.",
                                icon: "chart.line.uptrend.xyaxis",
                                color: .green
                            )
                            
                            InsightCard(
                                title: "Response Time Impact",
                                description: "Gigs with response times under 2 hours get 3x more bookings. Try to respond quickly!",
                                icon: "message.circle.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateWeeklyData() -> [WeeklyDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var data: [WeeklyDataPoint] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                data.append(WeeklyDataPoint(
                    date: date,
                    views: Int.random(in: 50...200),
                    impressions: Int.random(in: 200...600),
                    messages: Int.random(in: 2...10),
                    bookings: Int.random(in: 0...3)
                ))
            }
        }
        
        return data.reversed()
    }
    
    private func generateCategoryPerformance() -> [CategoryPerformance] {
        let categories = ["Creative", "Home", "Pet Care", "Tutoring", "Fitness"]
        return categories.map { category in
            CategoryPerformance(
                category: category,
                views: Int.random(in: 100...500),
                bookings: Int.random(in: 5...25),
                conversionRate: Double.random(in: 0.02...0.10)
            )
        }.sorted { $0.conversionRate > $1.conversionRate }
    }
}

extension AnalyticsView {
    static func currentUser(in context: NSManagedObjectContext) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

struct AnalyticsData {
    let totalViews: Int
    let totalImpressions: Int
    let totalMessages: Int
    let totalBookings: Int
    let clickThroughRate: Double
    let conversionRate: Double
    let averageResponseTime: Int
    let topPerformingGigs: [Gig]
    let weeklyData: [WeeklyDataPoint]
    let categoryPerformance: [CategoryPerformance]
}

struct WeeklyDataPoint {
    let date: Date
    let views: Int
    let impressions: Int
    let messages: Int
    let bookings: Int
}

struct CategoryPerformance {
    let category: String
    let views: Int
    let bookings: Int
    let conversionRate: Double
}

struct MetricCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundColor(isPositive ? .green : .red)
                    
                    Text(change)
                        .font(.caption)
                        .foregroundColor(isPositive ? .green : .red)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PerformanceChart: View {
    let data: [WeeklyDataPoint]
    
    var body: some View {
        VStack {
            // Simple bar chart representation
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    VStack {
                        Text("\(point.views)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Rectangle()
                            .fill(Color.appAccent.opacity(0.7))
                            .frame(width: 30, height: CGFloat(point.views) / 2)
                            .cornerRadius(4)
                        
                        Text(formatDate(point.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 150)
            
            Text("Views over time")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.appGrayLight)
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}

struct ConversionMetricRow: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                                        .foregroundColor(.appAccent)
        }
        .padding()
        .background(Color.appGrayLight)
        .cornerRadius(12)
    }
}

struct TopGigCard: View {
    let gig: Gig
    let rank: Int
    let views: Int
    let bookings: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("#\(rank)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(views) views")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(bookings) bookings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(gig.title ?? "Untitled Gig")
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text(gig.category ?? "Category")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("$\(String(format: "%.0f", gig.price))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.purple)
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CategoryPerformanceRow: View {
    let performance: CategoryPerformance
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(performance.category)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(performance.views) views • \(performance.bookings) bookings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f%%", performance.conversionRate * 100))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text("Conversion")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
} 