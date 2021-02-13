//
//  NotebookMO.swift
//  Notebooks
//
//  Created by Daniel Torres on 1/25/21.
//

import Foundation
import CoreData

public class NotebookMO: NSManagedObject {
    //no usar
    //init() { }
    
    //no usar
    //deinit { }

    //uniquing : todos los managed object representan un solo registro en nuestro persistent store.
    //fault : representan objetos que hacen referencia a registros en nuestro persistent store, pero que no cargados en memoria.
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        print("se creo un notebook.")
        
        //setear el valor de createdAtHumandReadable es un string.
    }
    
    public override func didTurnIntoFault() {
        super.didTurnIntoFault()
        
        print("se creo un fault.")
    }
    
    // Binary Large Data Objects (BLOBs)
        // Registro dentro de nuestro NSPersistentStore (sqlite) > 1 MB.
        // CLOB character large object de 128 bytes. (1 million de registro) es considerado un BLOBs.
        // normalizar con una tabla.
        // SQLite Store puede aumentar su tamaño 100 GB.
        // El normalizar los objetos en otra table aumenta los beneficios del Faulting.
        // a veces es mejor usar una URL a la imagen que queramos cargar.
    @discardableResult
    static func createNotebook(createdAt: Date,
                               title: String,
                               in managedObjectContext: NSManagedObjectContext) -> NotebookMO? {
        let notebook = NSEntityDescription.insertNewObject(forEntityName: "Notebook",
                                                           into: managedObjectContext) as? NotebookMO
        notebook?.createdAt = createdAt
        notebook?.title = title
        return notebook
    }
    
}

