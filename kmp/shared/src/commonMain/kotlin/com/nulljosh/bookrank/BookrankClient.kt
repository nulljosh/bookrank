package com.nulljosh.bookrank

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class Book(
    val section: String,
    val rank: Int,
    val title: String,
    val author: String,
    val goodreadsURL: String,
    val rating: Double,
    val reviewCount: String,
    val badges: List<String> = emptyList(),
    val notes: String = "",
    val cover: String = "",
)

// Reads the same static books.json the web app serves. bookrank has no
// backend at all, so there is nothing else to port.
class BookrankClient(private val baseUrl: String = "https://bookrank.heyitsmejosh.com") {
    private val http = HttpClient {
        install(ContentNegotiation) { json(Json { ignoreUnknownKeys = true }) }
    }

    suspend fun books(): List<Book> = http.get("$baseUrl/books.json").body()
}
