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
    var blockOperations = [BlockOperation]()
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
    
    deinit {
        for operation in blockOperations { operation.cancel() }
        blockOperations.removeAll()
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
    
    // Will change content.
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) { }
    
    // Did change a section.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            blockOperations.append(BlockOperation(block: { [weak self] in
                self?.collectionView.insertSections(IndexSet(integer: sectionIndex))
            }))
        case .delete:
            blockOperations.append(BlockOperation(block: { [weak self] in
                self?.collectionView.deleteSections(IndexSet(integer: sectionIndex))
            }))
        case .move, .update:
            break
        @unknown default: fatalError()
        }
    }
    
    // Did change an object.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        guard let newIndexPath = newIndexPath, let indexPath = indexPath else {
            return
        }
        switch type {
            case .insert:
                blockOperations.append(BlockOperation(block: { [weak self] in
                    self?.collectionView.insertItems(at: [newIndexPath])
                }))
            case .delete:
                blockOperations.append(BlockOperation(block: { [weak self] in
                    self?.collectionView.deleteItems(at: [indexPath])
                }))
            case .update:
                blockOperations.append(BlockOperation(block: { [weak self] in
                    self?.collectionView.reloadItems(at: [indexPath])
                }))
            case .move:
                blockOperations.append(BlockOperation(block: { [weak self] in
                    self?.collectionView.moveItem(at: indexPath, to: newIndexPath)
                }))
            @unknown default:
                break
        }
    }
    
    // Did change content.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({ () -> Void in
            for operation: BlockOperation in self.blockOperations { operation.start() }
        }, completion: { (finished) -> Void in self.blockOperations.removeAll() })
    }
}
