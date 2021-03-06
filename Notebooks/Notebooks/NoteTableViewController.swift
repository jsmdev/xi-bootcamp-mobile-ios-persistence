//
//  NoteTableViewController.swift
//  Notebooks
//
//  Created by Daniel Torres on 1/28/21.
//

import UIKit
import CoreData

class NoteTableViewController: UITableViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    var dataController: DataController?
    var fetchResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    var notebook: NotebookMO?
    
    public convenience init(dataController: DataController) {
        self.init()
        self.dataController = dataController
    }
    
    func initializeFetchResultsController() {
        // 1. Safe unwrapping de nuestro DataController.
        // notebook.
        guard let dataController = dataController,
            let notebook = notebook else {
            return
        }
        
        // 2. Crear nuestro NSFetchRequest
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        
        // 3. Seteamos el NSSortDescriptor.
        let noteCreatedAtSortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        fetchRequest.sortDescriptors = [noteCreatedAtSortDescriptor]
        
        // 4. Creamos nuestro NSPredicate.
        fetchRequest.predicate = NSPredicate(format: "notebook == %@", notebook)
        
        /// Notas Sobre Fetch Preficate and Sort descriptors.
        //1. No se puede colocar queries que son de SQL nativo dentro de los NSPredicates.
        //2. Solo se puede queries de uno a muchos elements dentro de nuestro key path/format en un NSPredicate.
        //3. No se pueden hacer sort descriptors con properties que son transients.
        
        // 5. Creamos el NSFetchResultsController.
        let managedObjectContext = dataController.viewContext
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                            managedObjectContext: managedObjectContext,
                                                            sectionNameKeyPath: nil,
                                                            cacheName: nil)
        
        fetchResultsController?.delegate = self
        
        // 6. Perform fetch.
        do {
            try fetchResultsController?.performFetch()
        } catch {
            fatalError("couldn't find notes \(error.localizedDescription) ")
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
        
        //crear un boton que abra el image picker y luego cuando se elija una imagen, se pueda agregar una nota con esa imagen.
        
        setupNavigationItem()
        setupSearchController()
    }
    
    func setupNavigationItem() {
        // crear un botón (uibarbutton)
        // setear ese botón con un metodo que pueda abrir el image picker.
        let addNoteBarButtonItem = UIBarButtonItem(title: "Add Note",
                                                   style: .done,
                                                   target: self,
                                                   action: #selector(createAndPresentImagePicker))
        
        navigationItem.rightBarButtonItem = addNoteBarButtonItem
    }
    
    private func setupSearchController() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search notes..."
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func searchNote(by title: String) {
        // Step 1.
        guard let dataController = dataController,
            let notebook = notebook else {
            return
        }
        
        // Step 2.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        
        // Step 3.
        let noteCreatedAtSortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [noteCreatedAtSortDescriptor]
        
        // Step 4.
        let predicateNotebook = NSPredicate(format: "notebook == %@", notebook)
        let predicateTitle = NSPredicate(format: "ANY title CONTAINS[c] %@", title)
        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [predicateNotebook, predicateTitle])
        fetchRequest.predicate = andPredicate
        
        // Step 5.
        let managedObjectContext = dataController.viewContext
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                            managedObjectContext: managedObjectContext,
                                                            sectionNameKeyPath: nil,
                                                            cacheName: nil)
        fetchResultsController?.delegate = self
        
        // Step 6.
        do {
            try fetchResultsController?.performFetch()
        } catch {
            fatalError("--- CORE DATA: couldn't find notes \(error.localizedDescription)")
        }
    }
    
    @objc
    func createAndPresentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        
        // necesitamos presentar los mediatypes disponibles en este caso solo photolibrary.
        if  UIImagePickerController.isSourceTypeAvailable(.photoLibrary),
            let availabletypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
            picker.mediaTypes = availabletypes
        }
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [unowned self] in
            if let urlImage = info[.imageURL] as? URL {
                
                // data controller para poder crear nuestra nota y photograph asociada.
                if let notebook = self.notebook {
                    self.dataController?.addNote(with: urlImage, notebook: notebook)
                }
            }
        }
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "noteCellIdentifier",
                                                 for: indexPath)
        
        guard let note = fetchResultsController?.object(at: indexPath) as? NoteMO else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        cell.textLabel?.text = note.title
        
        if let noteCreatedAt = note.createdAt, let photosCount = note.photographs?.count {
            cell.detailTextLabel?.text = "\(HelperDateFormatter.textFrom(date: noteCreatedAt)) - \(photosCount) photo(s)"
        }
        
        if let photograph = note.photographs?.allObjects.first as? PhotographMO, // relación a Photograph
           let imageData = photograph.imageData, // el atributo image data (donde posee la info de la imagen)
           let image = UIImage(data: imageData) { // aca creamos el uiimage necesario para nuestra celda.
            cell.imageView?.image = image // aca seteamos la uiimage del uiimageview en nuestra celda.
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let note = fetchResultsController?.object(at: indexPath) as? NoteMO {
            performSegue(withIdentifier: "noteDetailSegueIdentifier",
                         sender: note)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? NoteDetailViewController,
              let noteMO = sender as? NoteMO,
              let segueId = segue.identifier,
              segueId == "noteDetailSegueIdentifier" else { return }
        
        destination.note = noteMO
        destination.dataController = dataController
    }
}

// MARK:- NSFetchResultsControllerDelegate.
extension NoteTableViewController: NSFetchedResultsControllerDelegate {
    
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

// MARK:- UISearchResultsUpdating.
extension NoteTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text?.lowercased(), text.count >= 1 {
            searchNote(by: text)
            tableView.reloadData()
        }
    }
}

// MARK:- UISearchBarDelegate.
extension NoteTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        initializeFetchResultsController()
        tableView.reloadData()
    }
}
