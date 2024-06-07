//
//  ContentView.swift
//  SomeFeatureTests
//
//  Created by Arbab Nawaz on 6/5/24.
//

import SwiftUI
import SwiftData
import TipKit


// https://asynclearn.medium.com/define-rules-for-displaying-tips-in-tipkit-741d0d3d505f
// https://swiftwithmajid.com/2024/05/15/discovering-app-features-with-tipkit-rules/

enum FeedTip: Tip {
    
    //you want the value of "isPro" to return to its initial state (in this case false) the first time it's referenced, use the .transient option in the @Parameter property wrapper
    @Parameter(.transient)
    static var isPro: Bool = false

    //TipKit framework provides us to build custom rules is events. An event is a user action we can donate to. The main difference with the parameters is the persistence. Framework automatically stores the number of events that happened.
    // code defines the "itemAdded" event with an identifier
    // track the number of times the user has added (greateer than 2 in our case)
    static let itemAdded = Event(id: "itemAdded")
    static let itemDeleted = Event(id: "itemDeleted")

    case add
    case favorite
    case remove
    case copy
    
    // The TipKit framework provides the #Rule macro, which allows us to define dynamic rules based on the app state.
    // Rules property, which belongs to the Tip protocol, contains an array of rules that determine when the tip should be displayed.
    var rules: [Rule] {
        #Rule(Self.$isPro) { isPro in
            // show when isPro is true
            isPro == true
        }
        
        //You can specify that the event occurs within a time period using the donatedWithin(_:) function
        // This rule sets the tip to display when the itemAdded event has occurred greater than 2 times in the last week // you can add week .minute, .hour, .day,
//        #Rule(Self.itemAdded) {
//            $0.donations.donatedWithin(.week).count > 2
//        }
        
        // track the number of times the user has added (greateer than 2 in our case)
//        #Rule(Self.itemAdded) {
//            $0.donations.count > 2
//        }
//        
//        #Rule(Self.itemDeleted) {
//            $0.donations.count > 0
//        }
    }
    
    var image: Image? {
        switch self {
        case .add: Image(systemName: "plus")
        case .remove: Image(systemName: "minus.circle")
        case .favorite: Image(systemName: "star")
        default: nil
        }
    }

    var title: Text {
            switch self {
            case .add:
                Text("Add more items.")
            case .remove:
                Text("Delete items")
            case .favorite:
                Text("Favorite the items")
            default:
                Text("")
            }
        }
        
        var message: Text? {
            switch self {
            case .add:
                Text("You can add more items to the feed here.")
            case .remove:
                Text("You can delete items from the feed here.")
            case .favorite:
                Text("You can favorite your items here.")
            default:
                nil
            }
        }
        
        var actions: [Action] {
            switch self {
            case .add: [Action(id: "add", title: "Add")]
            case .remove: [Action(id: "remove", title: "Delete")]
            case .favorite: [Action(id: "favorite", title: "Favorite")]

            default: []
            }
        }
}

struct ContentView: View {
    @Environment(\.isPro) var isPro
    @Environment(\.modelContext) private var modelContext
    private weak var tipPopoverController: TipUIPopoverViewController?

    @Query private var items: [Item]

    var body: some View {
        //TipView(FeedTip.remove, arrowEdge: .top)
        NavigationSplitView {
            List {
                TipView(FeedTip.add, arrowEdge: .trailing)
                ForEach(items) { item in
                    print("Item Favorite \( item.timestamp):\( item.isFavorite)")
                    return NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        //Button("", systemImage: "star", action: {})
                        Button {
                            withAnimation {
                                item.isFavorite.toggle()
                            }
                        } label: {
                            Label("", systemImage: item.isFavorite ? "heart.fill": "star")
                               
                        }
                        .symbolEffect(.bounce, value: 1)
                        .contentTransition(.symbolEffect(.replace))
                        .onTapGesture {
                            print("Favorite:\( item.isFavorite)")
                            //item.isFavorite.toggle()
                        }
                        
                        Image(systemName: item.isFavorite ? "heart.fill": "star")
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(Color.accentColor)
                            .symbolEffect(.bounce, value: 1)
                            .contentTransition(.symbolEffect(.replace))
                            .onTapGesture {
                                withAnimation {
                                    //item.isFavorite.toggle()
                                }
                                //print("Favorite:\( item.isFavorite)")
                                item.isFavorite.toggle()
                        }

                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))

                    }
                }
                .onDelete(perform: deleteItems)
                Button("Add", systemImage: "plus", action: addItem)
                    .popoverTip(FeedTip.add)
            }.onAppear{
                FeedTip.isPro = true
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action:{ deleteItems(offsets: IndexSet(items.startIndex..<items.endIndex))}) {
                        Label("Delete Items", systemImage: "trash")
                    } 
                    .tipBackground(Material.regular)
                    .popoverTip(FeedTip.remove, arrowEdge: .top)  { action in
                        deleteItems(offsets: IndexSet(items.startIndex..<items.endIndex))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .popoverTip(FeedTip.add) { action in
                        if action.id == "add" {
                            addItem()
                        }
                    }
                }
            }
            .tipBackground(Material.regular)
            .popoverTip(FeedTip.add)


        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        // This code asynchronously registers the itemAdded 
        // event when the text is pressed.
        Task { await FeedTip.itemAdded.donate() }
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        Task { await FeedTip.itemDeleted.donate() }
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
