//
//  PhotographCollectionViewCell.swift
//  Notebooks
//
//  Created by José Sancho on 14/2/21.
//

import UIKit

class PhotographCollectionViewCell: UICollectionViewCell {
    static let identifier: String = String(describing: PhotographCollectionViewCell.self)
    
    @IBOutlet weak var fotoImageView: UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fotoImageView?.layer.borderColor = UIColor.lightGray.cgColor
        fotoImageView?.layer.borderWidth = 1
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        fotoImageView?.image = nil
    }
    
    func configure(with data: PhotographMO) {
        if let data = data.imageData {
        }
    }
}
