//
//  PhotographCollectionViewCell.swift
//  Notebooks
//
//  Created by José Sancho on 14/2/21.
//

import UIKit

class PhotographCollectionViewCell: UICollectionViewCell {
    static let identifier: String = String(describing: PhotographCollectionViewCell.self)
    
    @IBOutlet weak var photographImageView: UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        photographImageView?.layer.borderColor = UIColor.lightGray.cgColor
        photographImageView?.layer.borderWidth = 1
        photographImageView?.layer.masksToBounds = true
        photographImageView?.layer.cornerRadius = 6
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photographImageView?.image = nil
    }
}
