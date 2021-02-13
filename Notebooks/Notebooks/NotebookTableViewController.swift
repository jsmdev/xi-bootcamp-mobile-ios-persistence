//
//  NotebookTableViewController.swift
//  Notebooks
//
//  Created by Daniel Torres on 1/26/21.
//

import UIKit
import CoreData

class NotebookTableViewController: UITableViewController {
    
    var dataController: DataController?
    var fetchResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    public convenience init(dataController: DataController) {
        self.init()
        self.dataController = dataController
    }
    
    func initializeFetchResultsController() {
        guard let dataController = dataController else { return }
        let viewContext = dataController.viewContext
        
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        let notebookTitleSortDescriptor = NSSortDescriptor(key: "title",
                                                           ascending: true)
        request.sortDescriptors = [notebookTitleSortDescriptor]
        
        // Formas de mitigar el Fault Overhead:
            // Notebook -> notes -> [(fault Note), (fault Note), (fault Note)]
            // notebook.notes.first === Coredata buscar esa note dentro NSPersistentStore -> NoteMO.
            // significa que tienes problems de performance. ()
            // Cuando vayamos a pedir datos de un (fault Note). Es cuando disparamos un Fault fetch.
        
            //Batch Faulting. // let notes = [(fault Note), (fault Note), (fault Note)].
            // Se usa para filtrar Objetos faults. El Batch Faulting nos devuelve un array con los objetos cargados en memoria.
            // let predicate = NSPredicate(format: "self IN %@", notes)
        
            //Prefetching. // NotebookMO -> notes -> [NoteMO, NoteMO, NoteMO].
            //fetRequest.relationKeyPathForPrefetching = ["notes"]
        
        self.fetchResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                managedObjectContext: viewContext,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        self.fetchResultsController?.delegate = self
        
        do {
            try self.fetchResultsController?.performFetch()
        } catch {
            print("Error while trying to perform a notebook fetch.")
        }
    }
    
    init() {
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeFetchResultsController()
        
        // crear un boton en el nav item para cargar data
            // crear un barbutton item.
            // setar su funcionalidad
            // colocarlo en nuestro nav item.
            // y llamar a nuestro data controller para poder cargar data.
        let loadDataBarbuttonItem = UIBarButtonItem(title: "Load",
                                                    style: .done,
                                                    target: self,
                                                    action: #selector(loadData))
            
        // crear un boton en el nav item para borrar data.
            // crear un barbutton item.
            // setar su funcionalidad
            // colocarlo en nuestro nav item.
            // y llamar a nuestro data controller para poder borrar data.
        let deleteBarButtonItem = UIBarButtonItem(title: "Delete",
                                                  style: .done,
                                                  target: self,
                                                  action: #selector(deleteData))
        
        navigationItem.leftBarButtonItems = [deleteBarButtonItem, loadDataBarbuttonItem]
    }
    
    @objc
    func deleteData() {
        dataController?.save()
        dataController?.delete()
        dataController?.reset()
        initializeFetchResultsController()
        tableView.reloadData()
    }
    
    @objc
    func loadData() {
        dataController?.loadNotesInBackground()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchResultsController?.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchResultsController = fetchResultsController {
            return fetchResultsController.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "notebookCell",
                                                 for: indexPath)
        
        guard let notebook = fetchResultsController?.object(at: indexPath) as? NotebookMO else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        cell.textLabel?.text = notebook.title
        
        if let createdAt = notebook.createdAt {
            cell.detailTextLabel?.text = HelperDateFormatter.textFrom(date: createdAt)
        }
        
        if let photograph = notebook.photograph,
           let imageData = photograph.imageData,
           let image = UIImage(data: imageData) {
            cell.imageView?.image = image
        }
        
        return cell
    }
    
    //MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueId = segue.identifier,
           segueId == "noteSegueIdentifier" {
            // encontrar/castear el notetableviewcontroller.
            let destination = segue.destination as! NoteTableViewController
            // tenemos que encontar el notebook que elegimos.
            let indexPathSelected = tableView.indexPathForSelectedRow!
            let selectedNotebook = fetchResultsController?.object(at: indexPathSelected) as! NotebookMO
            // luego setear el notebook.
            destination.notebook = selectedNotebook
            // luego setear el dataController.
            destination.dataController = dataController
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "noteSegueIdentifier", sender: nil)
    }
}


// MARK:- NSFetchResultsControllerDelegate.
extension NotebookTableViewController: NSFetchedResultsControllerDelegate {
    
    // will change
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    // did change a section.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move, .update:
            break
        @unknown default: fatalError()
        }
    }
    
    // did change an object.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                tableView.reloadRows(at: [indexPath!], with: .fade)
            case .move:
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
            @unknown default:
                fatalError()
        }
    }
    
    // did change content.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
