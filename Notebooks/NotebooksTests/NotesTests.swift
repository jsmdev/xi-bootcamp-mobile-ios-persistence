//
//  NotesTests.swift
//  NotebooksTests
//
//  Created by Daniel Torres on 1/28/21.
//

import XCTest
import CoreData
@testable import Notebooks

class NotesTests: XCTestCase {

    private let modelName = "NotebooksModel"
    private let optionalStoreName = "NotebooksModelTest"
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName) { _ in }
        dataController.delete()
    }
    
    func testCreateAndSearchNote() {
        let expectation = XCTestExpectation(description: "datacontrollerInBackground")
       
        DispatchQueue.global(qos: .userInitiated).async {
            print("hacer test en background")
            
            DispatchQueue.main.async {
                let dataController = DataController(modelName: self.modelName,
                                                    optionalStoreName: self.optionalStoreName) { (_) in }
                
                //crear notas en nuestro view context.
                dataController.loadNotesIntoViewContext()
                //salvar notes del managedObjectContext.
                dataController.save()
                //reset/clean up managedObjectContext
                dataController.reset()
                
                //buscar notes.
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
                
                let notes = dataController.fetchNotes(using: fetchRequest)
                
                XCTAssertEqual(notes?.count, 3)
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testNoteViewController() {
        //instanciar nuestro DataController.
        let dataController = DataController(modelName: modelName,
                                            optionalStoreName: optionalStoreName) { (_) in }
        
        let managedObjectContext = dataController.viewContext
        
        let notebook = NotebookMO.createNotebook(createdAt: Date(),
                                                 title: "notebook1",
                                                 in: dataController.viewContext)
        
        //crear notes dentro nuestro managed object context.
        let note = NoteMO.createNote(managedObjectContext: managedObjectContext,
                                     notebook: notebook!,
                                     title: "note1",
                                     createdAt: Date())
        
        //crear un note viewController.
        let noteViewController = NoteTableViewController(dataController: dataController)
        noteViewController.notebook = notebook
        
        noteViewController.loadViewIfNeeded()
        
        let notes = noteViewController.fetchResultsController?.fetchedObjects as? [NoteMO]
        
        guard let noteFirstFound = notes?.first else {
            XCTFail()
            return
        }
        
        //comparar el numero de objetos dentro de nuestro NSFetchResultsController.
        XCTAssertEqual(notes?.count, 1)
        XCTAssertEqual(note, noteFirstFound)
    }
}

//como conformar con Equatable.
struct Mesa: Equatable {
    let id: String
    
    static func ==(lhs: Mesa, rhs: Mesa) -> Bool {
        return lhs.id == rhs.id
    }
}
