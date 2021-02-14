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
    
    var dataController: DataController?
    var fetchResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var blockOperations = [BlockOperation]()
    var note: NoteMO?
    let cellSize: CGFloat = (UIScreen.main.bounds.width - 50) / 3
    
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        layout.itemSize = CGSize(width: cellSize, height: cellSize)
        layout.minimumLineSpacing = 8
        layout.prepare()  // <-- call prepare before invalidateLayout
        layout.invalidateLayout()
        collectionView.layoutIfNeeded()
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
        setupCollectionView()
        setupAddImageButton()
        setupTextView()
    }
    
    private func loadData() {
        titleTextField.text = note?.title
        descriptionTextView.text = note?.comment
    }
    
    private func saveData() {
        note?.title = titleTextField.text
        note?.comment = descriptionTextView.text
        dataController?.save()
    }
    
    private func setupCollectionView() {
        collectionView?.delegate = self
        collectionView?.dataSource = self
    }

    private func setupTextView() {
        descriptionTextView.layer.cornerRadius = 6
        descriptionTextView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
        descriptionTextView.backgroundColor = UIColor.systemGroupedBackground
        descriptionTextView.layer.borderWidth = 1
    }

    private func setupAddImageButton() {
        let addImageBarButtonItem = UIBarButtonItem(title: "Add Image",
                                                  style: .done,
                                                  target: self,
                                                  action: #selector(addImagePressed))
        navigationItem.rightBarButtonItem = addImageBarButtonItem
    }
    
    @objc func addImagePressed() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        if  UIImagePickerController.isSourceTypeAvailable(.photoLibrary),
            let availabletypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
            picker.mediaTypes = availabletypes
        }
        present(picker, animated: true, completion: nil)
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

// MARK:- UICollectionViewDelegateFlowLayout.
extension NoteDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellSize, height: cellSize)
    }
}

// MARK:- UICollectionViewDataSource.
extension NoteDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fetchResultsController = fetchResultsController,
           let sections = fetchResultsController.sections {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotographCollectionViewCell.identifier,
                                                      for: indexPath) as? PhotographCollectionViewCell
        
        guard let photograph = fetchResultsController?.object(at: indexPath) as? PhotographMO else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        if let imageData = photograph.imageData,
           let image = UIImage(data: imageData) {
            cell?.photographImageView?.image = image
        }
        
        return cell ?? UICollectionViewCell()
    }
}

extension NoteDetailViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [unowned self] in
            if let urlImage = info[.imageURL] as? URL {
                if let note = self.note {
                    self.dataController?.addImage(with: urlImage, to: note)
                }
            }
        }
    }
}
