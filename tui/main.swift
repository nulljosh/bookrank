import Foundation
import SwiftTUI

// ponytail: same fetch-and-render shape as wordroot-tui/cadence-tui — kernel's
// lookup logic is a Cloudflare Function, nothing local to port.

struct SearchResult: Decodable, Identifiable {
    var id: String { title }
    let title: String
    let author: String?
    let section: String
}
struct SearchResponse: Decodable { let query: String; let total: Int; let results: [SearchResult] }

let args = Array(CommandLine.arguments.dropFirst())
guard let query = args.first else {
    print("usage: kernel-tui <search query> | kernel-tui share <link or token>")
    exit(1)
}

// `share <link>`: print a shared summary's chapters. Reads the same public RPC share.html
// uses; a token is the whole credential, no account.
struct Shared: Decodable { let title: String; let content: String }
func shared(_ link: String) async -> Shared? {
    var token = link
    if let r = link.range(of: "t=") { token = String(link[r.upperBound...]).components(separatedBy: "&")[0] }
    var req = URLRequest(url: URL(string: "https://api.jaybulb.com/rpc/shared_summary")!)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "content-type")
    req.httpBody = try? JSONSerialization.data(withJSONObject: ["t": token])
    guard let (data, _) = try? await URLSession.shared.data(for: req) else { return nil }
    return (try? JSONDecoder().decode([Shared].self, from: data))?.first
}
if query == "share" {
    guard args.count > 1 else { print("usage: kernel-tui share <link or token>"); exit(1) }
    let sem = DispatchSemaphore(value: 0)
    var out: Shared?
    Task { out = await shared(args[1]); sem.signal() }
    sem.wait()
    guard let out else { print("That link is not active."); exit(1) }
    print(out.title); print(String(repeating: "=", count: out.title.count)); print(out.content)
    exit(0)
}

func search(_ q: String) async -> SearchResponse? {
    guard let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: "https://kernel.jaybulb.com/api/search?q=\(encoded)&limit=5") else { return nil }
    guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
    return try? JSONDecoder().decode(SearchResponse.self, from: data)
}

struct ResultsCard: View {
    let query: String
    let response: SearchResponse?

    var body: some View {
        VStack(alignment: .leading) {
            Text("kernel: \(query)").bold()
            if let response {
                Text("\(response.total) match(es)")
                ForEach(response.results) { r in
                    Text("\(r.title) — \(r.author ?? "unknown")")
                }
            } else {
                Text("Could not reach kernel.jaybulb.com")
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
