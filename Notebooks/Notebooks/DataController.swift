//
//  DataController.swift
//  Notebooks
//
//  Created by Daniel Torres on 1/25/21.
//

import Foundation
import CoreData
import UIKit

class DataController: NSObject {
    private let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Multi-threading y porque?
    // nos permite ejecutar código en paralelo.
    // no nos vamos enfocar en performance pero en predecir lo que usuario quiera.
    // la UI o main thread necesita un "view" o "main" context que viva también en el main thread pero
    // que también sea nuestro source of truth o fuente de verdad.
    //
    // existen 2 tipos de managed object context.
    // NSMainQueueConcurrencyType vs NSPrivateQueueConcurrencyType.
    
    // serial queues vs concurrency queues.
    // serial queues nos permite ejecutar las tareas que le indiquemos al queue en orden.
    // concurrency van ejecutar las tareas de manera concurrente o en paralelo mientras vayan siendo
    // registradas en nuestro queue.
    
    // nuestros managed object context de tipo NSPrivateQueueConcurrencyType van a ejecutar sus tareas en orden.
    
    // 1. Existen 2 tipos managedobjectcontext.
    // 2. vamos a utilizar el NSPrivateQueueConcurrencyType para crear managed object context privados (background), y cargar y hacer modificaciones de nuestros datos.
    // 3. vamos a utilizar un viewcontext para presentar los datos del managedobjectcontext privado (background).
    
    @discardableResult
    init(modelName: String, optionalStoreName: String?, completionHandler: (@escaping (NSPersistentContainer?) -> ())) {
        if let optionalStoreName = optionalStoreName {
            let managedObjectModel = Self.manageObjectModel(with: modelName)
            self.persistentContainer = NSPersistentContainer(name: optionalStoreName,
                                                             managedObjectModel: managedObjectModel)
            super.init()
            
            persistentContainer.loadPersistentStores { [weak self] (description, error) in
                if let error = error {
                    fatalError("Couldn't load CoreData Stack \(error.localizedDescription)")
                }
                
                completionHandler(self?.persistentContainer)
            }
            
            persistentContainer.performBackgroundTask { (privateMOC) in
                // toda la carga y modificaciones de nuestro grafo de objetos.
                // luego cuando terminemos le decimos al privateMOC.save().
                // el privateMOC va a estar conectado con un viewcontext.
                // el viewContext va actualizar con los datos que estén dentro de nuestro privateMOC.
            }
            
        } else {
            
            self.persistentContainer = NSPersistentContainer(name: modelName)
            
            super.init()
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.persistentContainer.loadPersistentStores { [weak self] (description, error) in
                    if let error = error {
                        fatalError("Couldn't load CoreData Stack \(error.localizedDescription)")
                    }
                    
                    DispatchQueue.main.async {
                        completionHandler(self?.persistentContainer)
                    }
                }
            }
        }
    }
    
    func fetchNotebooks(using fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> [NotebookMO]? {
        do {
            return try persistentContainer.viewContext.fetch(fetchRequest) as? [NotebookMO]
        } catch {
            fatalError("Failure to fetch notebooks with context: \(fetchRequest), \(error)")
        }
    }
    
    func fetchNotes(using fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> [NoteMO]? {
        do {
            return try viewContext.fetch(fetchRequest) as? [NoteMO]
        } catch {
            fatalError("Failure to fetch Notes")
        }
    }
    
    func save() {
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("=== could not save view context ===")
            print("error: \(error.localizedDescription)")
        }
    }
    
    func reset() {
        persistentContainer.viewContext.reset()
    }
    
    func delete() {
        guard let persistentStoreUrl = persistentContainer
                .persistentStoreCoordinator.persistentStores.first?.url else {
            return
        }
        
        do {
            try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: persistentStoreUrl,
                                                                                      ofType: NSSQLiteStoreType,
                                                                                      options: nil)
        } catch {
            fatalError("could not delete test database. \(error.localizedDescription)")
        }
    }
    
    static func manageObjectModel(with name: String) -> NSManagedObjectModel {
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else {
            fatalError("Error could not find model.")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing managedObjectModel from: \(modelURL).")
        }
        
        return managedObjectModel
    }
    
    func performInBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        //creamos nuestro managedobjectcontext privado
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        //seteamos nuestro viewcontext
        privateMOC.parent = viewContext
        
        //ejecutamos el block dentro de este privateMOC.
        privateMOC.perform {
            block(privateMOC)
        }
    }
}

extension DataController {
    // Private context (background)
    func loadNotesInBackground() {
        performInBackground { (privateManagedObjectContext) in
            let managedObjectContext = privateManagedObjectContext
            // crear nuestro Note en el view context
            guard let notebook = NotebookMO.createNotebook(createdAt: Date(),
                                                           title: "notebook con notas",
                                                           in: managedObjectContext) else {
                return
            }
            
            NoteMO.createNote(managedObjectContext: managedObjectContext,
                              notebook: notebook,
                              title: "nota 1",
                              createdAt: Date())
            
            NoteMO.createNote(managedObjectContext: managedObjectContext,
                              notebook: notebook,
                              title: "nota 2",
                              createdAt: Date())
            
            NoteMO.createNote(managedObjectContext: managedObjectContext,
                              notebook: notebook,
                              title: "nota 3",
                              createdAt: Date())
            
            let notebookImage = UIImage(named: "notebookImage")
            
            if let dataNotebookImage = notebookImage?.pngData() {
                let photograph = PhotographMO.createPhoto(imageData: dataNotebookImage,
                                                          createdAt: Date(),
                                                          managedObjectContext: managedObjectContext)
            
                notebook.photograph = photograph
            }
            
            do {
                try managedObjectContext.save()
            } catch {
                fatalError("failure to save in background.")
            }
        }
    }
    
    // View context (main)
    func loadNotesIntoViewContext() {
        let managedObjectContext = viewContext
        // crear nuestro Note en el view context
        guard let notebook = NotebookMO.createNotebook(createdAt: Date(),
                                                       title: "notebook con notas",
                                                       in: managedObjectContext) else {
            return
        }
        
        NoteMO.createNote(managedObjectContext: managedObjectContext,
                          notebook: notebook,
                          title: "nota 1",
                          createdAt: Date())
        
        NoteMO.createNote(managedObjectContext: managedObjectContext,
                          notebook: notebook,
                          title: "nota 2",
                          createdAt: Date())
        
        NoteMO.createNote(managedObjectContext: managedObjectContext,
                          notebook: notebook,
                          title: "nota 3",
                          createdAt: Date())
        
        let notebookImage = UIImage(named: "notebookImage")
        
        if let dataNotebookImage = notebookImage?.pngData() {
            let photograph = PhotographMO.createPhoto(imageData: dataNotebookImage,
                                                      createdAt: Date(),
                                                      managedObjectContext: managedObjectContext)
        
            notebook.photograph = photograph
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("failure to save in background.")
        }
    }
    
    func loadNotebooksIntoViewContext() {
        let managedObjectContext = viewContext
        
        NotebookMO.createNotebook(createdAt: Date(),
                                  title: "notebook1",
                                  in: managedObjectContext)
        
        NotebookMO.createNotebook(createdAt: Date(),
                                  title: "notebook2",
                                  in: managedObjectContext)
        
        NotebookMO.createNotebook(createdAt: Date(),
                                  title: "notebook3",
                                  in: managedObjectContext)
    }
    
    func addNote(with urlImage: URL, notebook: NotebookMO) {
        performInBackground { (managedObjectContext) in
            guard let imageThumbnail = DownSampler.downsample(imageAt: urlImage),
                  let imageThumbnailData = imageThumbnail.pngData() else {
                return
            }
            
            // nsmanagedobjects representan un registro en nuestro persistent store.
            // utilizando el object id del objeto nuestro managedObjectContext puede recrear
            // el objeto en su grafo
            let notebookID = notebook.objectID
            let copyNotebook = managedObjectContext.object(with: notebookID) as! NotebookMO
            
            let photograhMO = PhotographMO.createPhoto(imageData: imageThumbnailData,
                                                       createdAt: Date(),
                                                       managedObjectContext: managedObjectContext)
            
            let note = NoteMO.createNote(managedObjectContext: managedObjectContext,
                                         notebook: copyNotebook,
                                         title: "titulo de nota",
                                         createdAt: Date())
            
            note?.photograph = photograhMO
            
            do {
                try managedObjectContext.save()
            } catch {
                fatalError("could not create note with thumbnail image in background.")
            }
        }
    }
}
