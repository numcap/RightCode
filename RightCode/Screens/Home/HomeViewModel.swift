//
//  HomeViewModel.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-14.
//

import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedNote: Note = Note()
    @Published var addSheetIsPresented: Bool = false
    @Published var isLoading: Bool = false
    @Published var editorIsPresented: Bool = false
    @Published var codePopupIsPresented: Bool = false
    @Published var sortingPreferences: SortingPreferences = SortingPreferences(sortingMethod: .date, sortingOrderASC: false)
    
    
    @AppStorage("localDrawings") var notesData: Data?
    @AppStorage("sortingPreference") var sortingPreferencesData: Data?
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)
    
    func loadNotes() {
        // this is checking if drawingData is nil, this is because it saves savedData to drawingsData, and if drawingsData is nil the if statement does not proceed
        if let savedData = notesData {
            do {
                print("trying to load drawings")
                notes = try JSONDecoder().decode([Note].self, from: savedData)
                print("loaded drawings")
            } catch {
                print("Error loading drawings: \(error)")
            }
        }
        
        if let savedData = sortingPreferencesData {
            do {
                print("loading sorting")
                sortingPreferences = try JSONDecoder().decode(SortingPreferences.self, from: savedData)
                print(sortingPreferences.sortingMethod)
                print(sortingPreferences.sortingOrderASC)
                sort(false)
            }
            catch {
                print("Error loading Sorting Preferences: \(error)")
            }
        }
    }
    
    func saveNotes() {
        do {
            for (index, drawing) in notes.enumerated() {
                if (drawing.id == selectedNote.id) {
                    notes[index] = selectedNote
                    notesData = try JSONEncoder().encode(notes)
                    print("saved drawing")
                    return
                }
                else {
                    print("No drawing to save (not in SelectedNote)")
                }
            }
        } catch {

        }
        
    }
    
    func addNote(_ newNote: Note) {
        
        notes.append(newNote)
        
        do {
            print("trying to save drawings")
            notesData = try JSONEncoder().encode(notes)
            loadNotes()
            print("saved drawings")
        } catch {
            print("Error saving drawings: \(error)")
        }
    }
    
    func saveNote(_ selectedNote: Note) {
        do {
            for (index, note) in notes.enumerated() {
                if (note.id == selectedNote.id) {
                    notes[index] = selectedNote
                    notesData = try JSONEncoder().encode(notes)
                    print("saved drawing")
                    return
                }
                else {
                    print("No drawing to save (in SelectedNote")
                }
            }
        }
        catch {
            
        }
    }
    
    func duplicateNote(_ selectedNote: Note) {
        let newNote = Note(
            title: selectedNote.title + "-copy",
            date: Date(),
            language: selectedNote.language,
            drawing: selectedNote.drawing
        )
        addNote(newNote)
    }
    
    func deleteNote(_ selectedNote: Note) {
        notes.removeAll { $0.id == selectedNote.id }
        do {
            notesData = try JSONEncoder().encode(notes)
            loadNotes()
            print("saved drawings")
        } catch {
            print("Error saving drawings: \(error)")
        }
    }
    
    func renameNote(_ newTitle: String, _ selectedNote: Note) -> Bool {
        
        if (notes.contains(where: { $0.title == newTitle })) {
            return false
        }
        
        self.selectedNote.title = newTitle
        saveNote(selectedNote)
        loadNotes()
        return true
    }
    
    func sort(_ saveSort: Bool) {
        withAnimation(.easeInOut) {
            switch sortingPreferences.sortingMethod {
            case .name:
                if (sortingPreferences.sortingOrderASC) {
                    notes = notes.sorted { $0.title > $1.title }
                } else {
                    notes = notes.sorted { $0.title < $1.title }
                }
            case .date:
                if (sortingPreferences.sortingOrderASC) {
                    notes = notes.sorted { $0.createdAt < $1.createdAt }
                } else {
                    notes = notes.sorted { $0.createdAt > $1.createdAt }
                }
            case .language:
                if (sortingPreferences.sortingOrderASC) {
                    notes = notes.sorted { $0.language.rawValue > $1.language.rawValue }
                }
                else {
                    notes = notes.sorted { $0.language.rawValue < $1.language.rawValue }
                }
            }
        }
        
//        saveNotes() // maybe keep or delete
        
        if saveSort {
            do {
                print("saving sorting")
                sortingPreferencesData = try JSONEncoder().encode(sortingPreferences)
            }
            catch {
                
            }
        }
    }
    
    func getOCRTask() {
        Task {
            do {
                let res = try await NetworkManager.shared.getOCRTask(
                    task_id: "kjanskdja"
                )
                print("res\n", res)
            } catch {

            }
        }
    }

    func getStreamedOCRTask(task_id: String) {
        Task {
            do {
                try await NetworkManager.shared.getStreamedOCRTask(
                    task_id: task_id
                ) { event in
                    
                    print(event)
                    if let error = event.result?.error {
                        print("ERROR:", error)
                        return
                    }
                    
                    if event.status == "completed" && event.result != nil {
                        print("FINAL EVENT:", event.result!)
                        Task {
                            self.selectedNote.scannedCode = (event.result?.result!)!
                            self.editorIsPresented = true
                            self.isLoading = false
                            self.saveNotes()
                        }
                    }
                }
            } catch {
                print("STREAM ERROR:", error)
            }
        }
    }

    func postOCRTask(currentNote: Note) {
        Task {
            do {
                let res = try await NetworkManager.shared.postOCRImage(
                    language: currentNote.language.rawValue.lowercased(),
                    title: currentNote.title,
                    drawing: currentNote.drawing.toUIImage()
                )
                
                print("This is the response", res)
                currentNote.hasBeenScanned = true
                isLoading = true

                if res.status != "processing" {
                    print("error with server since status is not processing")
                    throw URLError(.badServerResponse)
                }

                currentNote.mostRecentOCRTaskId = res.task_id!

                getStreamedOCRTask(task_id: currentNote.mostRecentOCRTaskId)

            } catch {
                print(error.localizedDescription)
            }
            
        }
    }
    
    func postExecuteTask(currentNote: Note) {
        Task {
            do {
                let resData = try await NetworkManager.shared.postExecuteCode(
                    code: currentNote.scannedCode,
                    language: currentNote.language.rawValue.lowercased()
                )
                currentNote.mostRecentExeTaskId = resData.task_id
                getStreamedExecuteTask(task_id: currentNote.mostRecentExeTaskId)
            } catch {

            }
        }
    }

    func getStreamedExecuteTask(task_id: String) {
        Task {
            try await NetworkManager.shared.getStreamedExecuteTask(
                task_id: task_id
            ) { event in
                if event.status == "success" {
                    Task {
                        print("Event", event)
                        self.selectedNote.codeResult = event.result
                        self.codePopupIsPresented = true
                        self.saveNotes()
                    }
                }
            }
        }
    }
}
