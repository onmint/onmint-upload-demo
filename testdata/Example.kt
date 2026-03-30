package com.example.weather

import kotlin.math.roundToInt

/**
 * Weather data processor that aggregates readings
 * from multiple sensor stations.
 */

data class WeatherReading(
    val stationId: String,
    val temperatureC: Double,
    val humidity: Int,
    val windSpeedKmh: Double,
    val timestamp: Long
)

data class StationSummary(
    val stationId: String,
    val avgTempC: Double,
    val avgHumidity: Int,
    val maxWindKmh: Double,
    val readingCount: Int
)

// Convert Celsius to Fahrenheit
fun celsiusToFahrenheit(c: Double): Double = c * 9.0 / 5.0 + 32.0

// Generate some dummy sensor readings
fun loadSampleReadings(): List<WeatherReading> = listOf(
    WeatherReading("STATION-A", 22.5, 65, 12.3, 1700000000),
    WeatherReading("STATION-A", 23.1, 63, 14.0, 1700003600),
    WeatherReading("STATION-A", 21.8, 70, 9.5, 1700007200),
    WeatherReading("STATION-B", 18.2, 80, 22.1, 1700000000),
    WeatherReading("STATION-B", 17.9, 82, 25.4, 1700003600),
    WeatherReading("STATION-C", 30.0, 45, 5.0, 1700000000),
    WeatherReading("STATION-C", 31.2, 42, 6.8, 1700003600),
    WeatherReading("STATION-C", 29.8, 48, 4.2, 1700007200),
    WeatherReading("STATION-C", 32.5, 40, 7.1, 1700010800),
)

// Aggregate readings per station into summaries
fun summarizeByStation(readings: List<WeatherReading>): List<StationSummary> {
    return readings.groupBy { it.stationId }.map { (id, group) ->
        StationSummary(
            stationId = id,
            avgTempC = (group.map { it.temperatureC }.average() * 10).roundToInt() / 10.0,
            avgHumidity = group.map { it.humidity }.average().roundToInt(),
            maxWindKmh = group.maxOf { it.windSpeedKmh },
            readingCount = group.size
        )
    }
}

// Find the hottest station based on average temperature
fun findHottestStation(summaries: List<StationSummary>): StationSummary? {
    return summaries.maxByOrNull { it.avgTempC }
}

fun main() {
    val readings = loadSampleReadings()
    val summaries = summarizeByStation(readings)

    println("=== Weather Station Summaries ===")
    for (s in summaries) {
        val tempF = celsiusToFahrenheit(s.avgTempC)
        println("${s.stationId}: avg ${s.avgTempC}°C (${String.format("%.1f", tempF)}°F), " +
                "humidity ${s.avgHumidity}%, max wind ${s.maxWindKmh} km/h, " +
                "${s.readingCount} readings")
    }

    val hottest = findHottestStation(summaries)
    hottest?.let { println("\nHottest station: ${it.stationId} at ${it.avgTempC}°C") }
}
