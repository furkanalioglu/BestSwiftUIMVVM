//
//  ContentView.swift
//  BestMVVMSwiftUI
//
//  Created by Furkan Alioglu on 20.10.2023.
//
import SwiftUINavigation
import SwiftUI
import Combine

final
class StandupsListModel: ObservableObject {
    @Published var standups : [Standup]
    @Published var destination: Destination?
    { didSet { self.bind() } }
    
    private var destinationCancellable : AnyCancellable?
    
    enum Destination {
        case add(EditStandupModel)
        case detail(StandupDetailModel)
    }
    
    init(standups: [Standup] = [],
         destination : Destination? = nil) {
        self.standups = standups
        self.destination = destination
        self.bind()
    }
    
    func addStandupButtonTapped() {
        self.destination = .add(EditStandupModel(standup:Standup(id: Standup.ID(UUID()))))
    }
    
    func dismissAddStandupButtonTapped() {
        self.destination = nil
    }
    
    func confirmAddStandupButtonTapped() {
        defer { self.destination = nil }
        
        guard case let .add(editStandupModel) = self.destination
        else { return }
        var standup = editStandupModel.standup
                
        standup.attendees.removeAll { attendee in
            attendee.name.allSatisfy(\.isWhitespace)
        }
        
        if standup.attendees.isEmpty{
            standup.attendees.append(Attendee(id: Attendee.ID(UUID()), name: ""))
        }
        self.standups.append(standup)
    }
    
    func standupTapped(standup : Standup) {
        self.destination = .detail(StandupDetailModel(standup: standup))
    }
    
    private
    func bind() {
        switch self.destination {
        case .detail(let standupDetailModel):
            standupDetailModel.onConfirmDeletion = {
                [weak self, id = standupDetailModel.standup.id] in
                guard let self else { return }
                
                withAnimation {
                    //NOT THE BEST WAY
                    self.standups.removeAll {$0.id == id}
                    self.destination = nil
                }
            }
            
            self.destinationCancellable = standupDetailModel.$standup
                .sink { [weak self] standup in
                    guard let self else { return }
                    guard let index = self.standups.firstIndex(where: {$0.id == standup.id})
                    else { return }
                self.standups[index] = standup
            }
            break
            
        case .add, .none:
            break
        }
    }
}

struct StandupsList: View {
    @ObservedObject var  model: StandupsListModel
    var body: some View {
        NavigationStack{
            List{
                ForEach(self.model.standups) { standup in
                    Button{
                        self.model.standupTapped(standup:standup)
                    }label:{
                        CardView(standup: standup)
                    }
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
            { $model in
                NavigationStack{
                    EditStandupView(model: model)
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
            }.navigationDestination(unwrapping: self.$model.destination,
                                    case: CasePath(StandupsListModel.Destination.detail))
            { $detailModel in
                StandupDetail(model: detailModel)
            }
        }
    }
}

#Preview {
    StandupsList(
        model: StandupsListModel(
            standups: [.mock],
            destination: .add(EditStandupModel(
                standup: .mock,
                focus: .attendee(
                    Standup.mock.attendees[1].id))
            )
        )
    )
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
