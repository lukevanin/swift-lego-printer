//
//  DocumentBrowserViewController.swift
//  Printy
//
//  Created by Luke Van In on 2022/11/24.
//

import UIKit


final class DocumentBrowserViewController: UIDocumentBrowserViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
    }
}
