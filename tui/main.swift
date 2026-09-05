import Foundation
import SwiftTUI

// ponytail: same fetch-and-render shape as wordroot-tui/cadence-tui — bookrank's
// lookup logic is a Cloudflare Function, nothing local to port.

struct SearchResult: Decodable, Identifiable {
    var id: String { title }
    let title: String
    let author: String?
    let section: String
}
struct SearchResponse: Decodable { let query: String; let total: Int; let results: [SearchResult] }

let args = CommandLine.arguments.dropFirst()
guard let query = args.first else {
    print("usage: bookrank-tui <search query>")
    exit(1)
}

func search(_ q: String) async -> SearchResponse? {
    guard let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: "https://bookrank.heyitsmejosh.com/api/search?q=\(encoded)&limit=5") else { return nil }
    guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
    return try? JSONDecoder().decode(SearchResponse.self, from: data)
}

struct ResultsCard: View {
    let query: String
    let response: SearchResponse?

    var body: some View {
        VStack(alignment: .leading) {
            Text("bookrank: \(query)").bold()
            if let response {
                Text("\(response.total) match(es)")
                ForEach(response.results) { r in
                    Text("\(r.title) — \(r.author ?? "unknown")")
                }
            } else {
                Text("Could not reach bookrank.heyitsmejosh.com")
            }
        }
        .padding()
        .border()
    }
}

let semaphore = DispatchSemaphore(value: 0)
var response: SearchResponse?
Task {
    response = await search(query)
    semaphore.signal()
}
semaphore.wait()

Application(rootView: ResultsCard(query: query, response: response)).start()
