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
    
    var note: NoteMO?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.text = note?.title
        descriptionTextView.text = note?.description
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
