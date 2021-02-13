//
//  NotebookTableViewControllerTests.swift
//  NotebooksTests
//
//  Created by Daniel Torres on 1/26/21.
//

import XCTest
import CoreData
@testable import Notebooks

class NotebookTableViewControllerTests: XCTestCase {
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

    func testFetchResultsController_FetchNotebooksInViewContext_InMemory() {
        let dataController = DataController(modelName: modelName,
                                            optionalStoreName: optionalStoreName) { (_) in }
        
        dataController.loadNotebooksIntoViewContext()
        
        let notebookViewController = NotebookTableViewController(dataController: dataController)
        
        notebookViewController.loadViewIfNeeded()
        
        let foundNotebooks = notebookViewController.fetchResultsController?.fetchedObjects?.count
        
        XCTAssertEqual(foundNotebooks, 3)
    }
    
    func testFetchResultsController_FetchNotebooksInViewContext_InPersistentStore() {
        let dataController = DataController(modelName: modelName,
                                            optionalStoreName: optionalStoreName) { (pers) in }
        
        //cargamos objectos en memoria
        dataController.loadNotebooksIntoViewContext()
        //mandamos a guardar
        dataController.save()
        //hacemos un clean up de nuestro view context.
        dataController.reset()
        
        //creamos nuestro viewcontroller y su fetchresultscontroller
        let notebookViewController = NotebookTableViewController(dataController: dataController)
        
        //pedimos que carga la vista de nuestro vc, por lo tanto ejecuta el viewdidload()
        //y por lo tanto hace que el fetchresultscontroller empiece a buscar.
        notebookViewController.loadViewIfNeeded()
        
        //comparamos entonces los resultados.
        let foundNotebooks = notebookViewController.fetchResultsController?.fetchedObjects?.count
        
        XCTAssertEqual(foundNotebooks, 3)
    }
}
