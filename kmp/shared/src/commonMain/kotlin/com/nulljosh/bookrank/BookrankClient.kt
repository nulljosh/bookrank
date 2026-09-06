package com.nulljosh.bookrank

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
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

/** One summary behind a share link: title, text, cover and the cached narration only. */
@Serializable
data class SharedSummary(val title: String, val content: String, val cover: String? = null)

/** Chapters: coarsest heading level with at least two ("# " before "## "), same rule as listen.js. */
fun chapters(md: String): List<Pair<String, String>> {
    fun split(mark: String): List<Triple<String, String, String>> {
        val out = mutableListOf<Triple<String, String, String>>()
        var cur: MutableList<String>? = null
        fun flush() = cur?.let { ls ->
            out += Triple(ls[0].drop(mark.length + 1).trim(), ls.joinToString("\n"), ls.drop(1).joinToString("\n").trim())
        }
        for (line in md.lines()) {
            if (line.startsWith("$mark ")) { flush(); cur = mutableListOf(line) } else cur?.add(line)
        }
        flush()
        return out
    }
    val h1 = split("#").filterIndexed { i, c -> i > 0 || c.third.isNotEmpty() }
    val h2 = split("##")
    val parts = if (h1.size > 1) h1 else if (h2.isNotEmpty()) h2 else h1
    if (parts.isEmpty()) return if (md.isBlank()) emptyList() else listOf("Whole book" to md)
    return parts.map { it.first to it.second }
}

// Reads the same static books.json the web app serves, plus shared summaries via the
// public RPC (no account needed, a token is the whole credential).
class BookrankClient(private val baseUrl: String = "https://bookrank.heyitsmejosh.com") {
    private val http = HttpClient {
        install(ContentNegotiation) { json(Json { ignoreUnknownKeys = true }) }
    }

    suspend fun books(): List<Book> = http.get("$baseUrl/books.json").body()

    /** Accepts a share URL or a bare token. Null when the link is not active. */
    suspend fun shared(linkOrToken: String): SharedSummary? {
        val token = linkOrToken.substringAfter("t=", linkOrToken).substringBefore("&").trim()
        if (token.length < 8) return null
        val rows: List<SharedSummary> = http.post("$SUPABASE/rest/v1/rpc/shared_summary") {
            header("apikey", ANON)
            contentType(ContentType.Application.Json)
            setBody(mapOf("t" to token))
        }.body()
        return rows.firstOrNull()
    }

    private companion object {
        const val SUPABASE = "https://tjsxsqlxjmanwvmywwvw.supabase.co"
        const val ANON = "sb_publishable_3a5WLExQ3oF_kPV3KRCjdg_iEOiHO90"
    }
}
