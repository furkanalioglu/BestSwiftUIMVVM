//
//  StandupDetailModel.swift
//  BestMVVMSwiftUI
//
//  Created by Furkan Alioglu on 21.10.2023.
//

import Foundation
import SwiftUI
import SwiftUINavigation
import XCTestDynamicOverlay


@MainActor
final
class StandupDetailModel : ObservableObject {
    enum Destination {
        case alert(AlertState<AlertAction>)
        case meeting(Meeting)
        case edit(EditStandupModel)
        case record(RecordMeetingModel)
    }
    
    enum AlertAction {
        case confirmDeletion
    }
    
    @Published var destination: Destination?{
        didSet{ self.bind() }
    }
    @Published var standup: Standup
    
    var onConfirmDeletion: () -> Void = unimplemented("StandupDetailModel.onConfirmDeletion")
    
    init(destination: Destination? = nil ,
         standup: Standup) {
        self.destination = destination
        self.standup = standup
        self.bind()
    }
    
    func deleteMeeting(atOffsets indices: IndexSet) {
        self.standup.meetings.remove(atOffsets: indices)
    }
    
    func meetingTapped(_ meeting: Meeting) {
        self.destination = .meeting(meeting)
    }
    
    func deleteButtonTapped() {
        self.destination = .alert(.delete)
    }
    
    func alertButtonTapped(_ action: AlertAction ){
        switch action{
        case .confirmDeletion:
            self.onConfirmDeletion()
        }
    }
    
    func editButtonTapped() {
        self.destination = .edit(EditStandupModel(standup: self.standup))
    }
    
    func cancelEditButtonTapped() {
        self.destination = nil
    }
    
    func doneEditButtonTapped() {
        guard case let .edit(model) = self.destination
        else { return }
        
        self.standup = model.standup
        self.destination = nil
    }
    
    func startMeetingButtonTapped() {
        self.destination = .record(RecordMeetingModel(standup: self.standup))
    }
    
    private
    func bind() {
        switch self.destination{
        case let .record(recordMeetingModel):
            recordMeetingModel.onMeetingFinished = { [weak self] transcript in
                guard let self else { return }
                
                Task{
                    try? await Task.sleep(for: .milliseconds(100))
                    withAnimation{
                    //since there is a swiftui bug do not uncomment it
                    _ = self.standup.meetings.insert(
                        Meeting(id: Meeting.ID(UUID()),
                                date: Date(),
                                transcript: transcript),
                        at: 0)
                    }
                }
//                self.destination = nil
            }
            break
        case .alert, .edit, .meeting, .none:
            break
        }
    }
}

struct StandupDetail : View {
    @ObservedObject var model: StandupDetailModel
    var body: some View {
        List {
            Section {
                Button {
                    self.model.startMeetingButtonTapped()
                } label: {
                    Label("Start Meeting", systemImage: "timer")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                HStack {
                    Label("Length", systemImage: "clock")
                    Spacer()
                    Text(self.model.standup.duration.formatted(
                        .units())
                    )
                }
                
                HStack {
                    Label("Theme", systemImage: "paintpalette")
                    Spacer()
                    Text(self.model.standup.theme.name)
                        .padding(4)
                        .foregroundColor(
                            self.model.standup.theme.accentColor
                        )
                        .background(self.model.standup.theme.mainColor)
                        .cornerRadius(4)
                }
            } header: {
                Text("Standup Info")
            }
            
            if !self.model.standup.meetings.isEmpty {
                Section {
                    ForEach(self.model.standup.meetings) { meeting in
                        Button {
                            self.model.meetingTapped(meeting)
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                Text(meeting.date, style: .date)
                                Text(meeting.date, style: .time)
                            }
                        }
                    }
                    .onDelete { indices in
                        model.deleteMeeting(atOffsets: indices)
                    }
                } header: {
                    Text("Past meetings")
                }
            }
            
            Section {
                ForEach(self.model.standup.attendees) { attendee in
                    Label(attendee.name, systemImage: "person")
                }
            } header: {
                Text("Attendees")
            }
            
            Section {
                Button("Delete") {
                    self.model.deleteButtonTapped()
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(self.model.standup.title)
        .toolbar {
            Button("Edit") {
                self.model.editButtonTapped()
            }
        }
        .navigationDestination(
            unwrapping: self.$model.destination,
            case: CasePath(
                StandupDetailModel.Destination.meeting))
        { $meeting in
            MeetingView(meeting: meeting, standup: self.model.standup)
        }
        .navigationDestination(
            unwrapping: self.$model.destination,
            case: CasePath(
                StandupDetailModel.Destination.record))
        { $recordMeeting in
            RecordMeetingView(model: recordMeeting)
                .id("123123")
        }                .interactiveDismissDisabled()

        .alert(unwrapping: self.$model.destination,
               case:  CasePath(
                StandupDetailModel.Destination.alert),
               action: { action in
            if let actualAction = action {
                self.model.alertButtonTapped(actualAction)
            }
        })
        .sheet(
            unwrapping: self.$model.destination,
            case: CasePath(
                StandupDetailModel.Destination.edit))
        { $editmodel in
            NavigationStack {
                EditStandupView(model: editmodel)
                    .navigationTitle(self.model.standup.title)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel"){
                                self.model.cancelEditButtonTapped()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done"){
                                self.model.doneEditButtonTapped()
                            }
                        }
                    }
            }
        }

    }
}

extension AlertState where Action == StandupDetailModel.AlertAction{
    static let delete = AlertState(
        title: TextState("Are you sure you want to delete"),
        message: TextState("You can not recover your deleted meetings"),
        buttons: [
            .destructive(TextState("Yes"),
                         action: .send(.confirmDeletion)),
            .cancel(TextState("Nevermind"))
        ]
    )
}

struct MeetingView: View {
    let meeting: Meeting
    let standup: Standup
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Divider()
                    .padding(.bottom)
                Text("Attendees")
                    .font(.headline)
                ForEach(self.standup.attendees) { attendee in
                    Text(attendee.name)
                }
                Text("Transcript")
                    .font(.headline)
                    .padding(.top)
                Text(self.meeting.transcript)
            }
        }
        .navigationTitle(
            Text(self.meeting.date, style: .date)
        )
        .padding()
    }
}
