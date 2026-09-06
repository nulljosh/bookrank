package com.nulljosh.bookrank

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.TextButton
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun BookrankTheme(content: @Composable () -> Unit) =
    MaterialTheme(colorScheme = lightColorScheme(), content = content)

@Composable
fun AppScreen(client: BookrankClient = BookrankClient()) {
    var books by remember { mutableStateOf<List<Book>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    var shared by remember { mutableStateOf<SharedSummary?>(null) }

    LaunchedEffect(Unit) {
        runCatching { books = client.books() }.onFailure { error = it.message ?: "failed to load" }
        loading = false
    }

    shared?.let { SharedScreen(it) { shared = null } ; return }

    Surface {
        Column(Modifier.fillMaxSize().padding(24.dp)) {
            Text("Bookrank", style = MaterialTheme.typography.headlineMedium)
            ShareLinkBox(client) { shared = it }
            when {
                loading -> CircularProgressIndicator(Modifier.padding(top = 24.dp))
                error != null -> Text(error!!, modifier = Modifier.padding(top = 16.dp))
                else -> LazyColumn(
                    modifier = Modifier.padding(top = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    items(books.sortedBy { it.rank }) { b ->
                        Column {
                            Text("${b.rank}. ${b.title}", style = MaterialTheme.typography.titleMedium)
                            Text("${b.author} - ${b.rating}★ (${b.reviewCount})")
                        }
                    }
                }
            }
        }
    }
}

/** Paste a bookrank share link to read that summary here. No account, no position, just the text. */
@Composable
private fun ShareLinkBox(client: BookrankClient, onOpen: (SharedSummary) -> Unit) {
    var link by remember { mutableStateOf("") }
    var msg by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    Row(Modifier.padding(top = 12.dp)) {
        OutlinedTextField(link, { link = it }, label = { Text("Share link") }, singleLine = true, modifier = Modifier.weight(1f))
        Spacer(Modifier.width(8.dp))
        Button(onClick = {
            scope.launch {
                val s = runCatching { client.shared(link) }.getOrNull()
                if (s == null) msg = "That link is not active." else onOpen(s)
            }
        }) { Text("Open") }
    }
    msg?.let { Text(it, style = MaterialTheme.typography.bodySmall) }
}

@Composable
private fun SharedScreen(s: SharedSummary, onBack: () -> Unit) {
    val chs = remember(s) { chapters(s.content) }
    var ch by remember { mutableStateOf(0) }
    Surface {
        Column(Modifier.fillMaxSize().padding(24.dp)) {
            TextButton(onClick = onBack) { Text("Back") }
            Text(s.title, style = MaterialTheme.typography.headlineMedium)
            Row(Modifier.padding(top = 16.dp)) {
                LazyColumn(Modifier.width(220.dp)) {
                    items(chs.indices.toList()) { i ->
                        TextButton(onClick = { ch = i }) {
                            Text(chs[i].first, style = if (i == ch) MaterialTheme.typography.titleSmall else MaterialTheme.typography.bodySmall)
                        }
                    }
                }
                Spacer(Modifier.width(24.dp))
                Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
                    // ponytail: markdown shown as plain text; add a renderer if the read view is used much
                    Text(chs.getOrNull(ch)?.second ?: s.content)
                }
            }
        }
    }
}
