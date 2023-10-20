//
//  ContentView.swift
//  BestMVVMSwiftUI
//
//  Created by Furkan Alioglu on 20.10.2023.
//
import SwiftUINavigation
import SwiftUI

final
class StandupsListModel: ObservableObject {
    @Published var standups : [Standup]
    @Published var destination: Destination?
    
    enum Destination {
        case add(Standup)
    }
    
    init(standups: [Standup] = [],
         destination : Destination? = nil) {
        self.standups = standups
        self.destination = destination
    }
    
    func addStandupButtonTapped() {
        self.destination = .add(Standup(id: Standup.ID(UUID())))
    }
}

struct StandupsList: View {
    @ObservedObject var  model: StandupsListModel
    var body: some View {
        NavigationStack{
            List{
                ForEach(self.model.standups) { standup in
                    CardView(standup: standup)
                        .listRowBackground(standup.theme.mainColor)
                }
            }
            .toolbar{
                Button{
                    self.model.addStandupButtonTapped()
                }label: {
                    Image(systemName: "plus")
                }
            }
            .navigationTitle("Daily standups")
            .sheet(
                unwrapping: self.$model.destination,
                   //nil represents no sheet presented non nil represent sheet presented
                // this dollar sign only possible thanks to keypads
                case: CasePath(StandupsListModel.Destination.add))
            { $standup in
                NavigationStack{
                    EditStandupView(standup: $standup)
                        .navigationTitle("Edit standup")
                }
                //The apple's binding state api is the missing puzzle in that part
                //There was no way to inspect view had mutated child view
                
            }
        }
    }
}

#Preview {
    NavigationStack{
        StandupsList(model: StandupsListModel(standups: [.mock]))
    }
}

struct CardView: View {
  let standup: Standup

  var body: some View {
    VStack(alignment: .leading) {
      Text(self.standup.title)
        .font(.headline)
      Spacer()
      HStack {
        Label("\(self.standup.attendees.count)", systemImage: "person.3")
        Spacer()
        Label(self.standup.duration.formatted(.units()), systemImage: "clock")
              .labelStyle(.titleAndIcon)
      }
      .font(.caption)
    }
    .padding()
    .foregroundColor(self.standup.theme.accentColor)
  }
}
