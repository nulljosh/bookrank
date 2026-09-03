import SwiftUI

struct ContentView: View {
    @State private var store = BookStore()

    var body: some View {
        TabView {
            ShelfView(store: store)
            ToReadView(store: store)
            TopPicksView(store: store)
        }
        .tabViewStyle(.verticalPage)
    }
}
