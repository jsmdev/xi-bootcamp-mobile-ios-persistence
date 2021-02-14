//
//  NoteDetailViewController.swift
//  Notebooks
//
//  Created by José Sancho on 13/2/21.
//

import UIKit
import CoreData

class NoteDetailViewController: ViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var saveButton: UIButton!
    
    var dataController: DataController?
    var fetchResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var note: NoteMO?
    
    public convenience init(dataController: DataController) {
        self.init()
        self.dataController = dataController
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        initializeFetchResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveData()
    }
    
    func initializeFetchResultsController() {
        // 1. Unwrapping DataController and Note Managed Object
        guard let dataController = dataController,
            let note = note else {
            return
        }
        
        // 2. Create the NSFetchRequest
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photograph")
        
        // 3. Create the NSSortDescriptor.
        let noteCreatedAtSortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        fetchRequest.sortDescriptors = [noteCreatedAtSortDescriptor]
        
        // 4. Create the NSPredicate.
        fetchRequest.predicate = NSPredicate(format: "note == %@", note)
 
        // 5. Create the NSFetchResultsController.
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
            fatalError("Couldn't find photos \(error.localizedDescription)")
        }
    }
    
    private func setupUI() {
        let addImageBarButtonItem = UIBarButtonItem(title: "Add Image",
                                                  style: .done,
                                                  target: self,
                                                  action: #selector(addImagePressed))
        navigationItem.rightBarButtonItem = addImageBarButtonItem
    }
    
    private func loadData() {
        titleTextField.text = note?.title
        descriptionTextView.text = note?.description
    }
    
    private func saveData() {
        note?.title = titleTextField.text
        dataController?.save()
    }
    
    @objc func addImagePressed() {
    }
}

// MARK:- NSFetchResultsControllerDelegate.
extension NoteDetailViewController: NSFetchedResultsControllerDelegate {
    
    
}
