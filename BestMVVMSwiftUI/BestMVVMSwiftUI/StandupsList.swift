//
//  ContentView.swift
//  BestMVVMSwiftUI
//
//  Created by Furkan Alioglu on 20.10.2023.
//

import SwiftUI

final
class StandupsListModel: ObservableObject {
    @Published var standups : [Standup]
    
    init(standups: [Standup] = []) {
        self.standups = standups
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
            }.navigationTitle("Daily standups")
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
