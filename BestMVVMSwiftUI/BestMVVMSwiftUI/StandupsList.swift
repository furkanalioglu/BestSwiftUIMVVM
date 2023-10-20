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
    
    func dismissAddStandupButtonTapped() {
        self.destination = nil
    }
    
    func confirmAddStandupButtonTapped() {
        defer { self.destination = nil }
        
        guard case var .add(standup) = self.destination
        else { return }
        
        standup.attendees.removeAll { attendee in
            attendee.name.allSatisfy(\.isWhitespace)
        }
        
        if standup.attendees.isEmpty{
            standup.attendees.append(Attendee(id: Attendee.ID(UUID()), name: ""))
        }
        self.standups.append(standup)
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
                case: CasePath(StandupsListModel.Destination.add))
            { $standup in
                NavigationStack{
                    EditStandupView(standup: $standup)
                        .navigationTitle("Edit standup")
                        .toolbar{
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Dismiss") {
                                    self.model.dismissAddStandupButtonTapped()
                                }
                            }
                            
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Add") {
                                    self.model.confirmAddStandupButtonTapped()
                                }
                            }
                        }
                }
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
