//
//  NoteDetailViewController.swift
//  Notebooks
//
//  Created by José Sancho on 13/2/21.
//

import UIKit

class NoteDetailViewController: ViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var saveButton: UIButton!
    
    var dataController: DataController?
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveData()
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
