//
//  ArtistView.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 04/11/2024.
//

import Cocoa

class ArtistViewModel {
    let name: String
    var isSelected: Bool
    
    init(name: String, isSelected: Bool = false) {
        self.name = name
        self.isSelected = isSelected
    }
}

class ArtistViewController: NSViewController {
    var tableView = NSTableView()
        
    var artistViewModels: [ArtistViewModel] = [
            ArtistViewModel(name: "Artist 1"),
            ArtistViewModel(name: "Artist 2"),
            ArtistViewModel(name: "Artist 3"),
            ArtistViewModel(name: "Artist 4")
        ]
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            tableView.delegate = self
            tableView.dataSource = self
        }

    }

    extension ArtistViewController: NSTableViewDataSource {
        func numberOfRows(in tableView: NSTableView) -> Int {
            return artistViewModels.count
        }
    }

    extension ArtistViewController: NSTableViewDelegate {
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let artistViewModel = artistViewModels[row]
            
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("ArtistCell"), owner: self) as? NSTableCellView {
                if let checkbox = cell.viewWithTag(1) as? NSButton {
                    checkbox.title = artistViewModel.name
                    checkbox.state = artistViewModel.isSelected ? .on : .off
                    checkbox.target = self
                    checkbox.action = #selector(checkboxToggled(_:))
                    checkbox.tag = row
                }
                return cell
            }
            
            let cell = NSTableCellView()
            let checkbox = NSButton(checkboxWithTitle: artistViewModel.name, target: self, action: #selector(checkboxToggled(_:)))
            checkbox.tag = row
            checkbox.state = artistViewModel.isSelected ? .on : .off
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(checkbox)
            NSLayoutConstraint.activate([
                checkbox.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 5),
                checkbox.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -5),
                checkbox.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            ])
            return cell
        }
        
        @objc func checkboxToggled(_ sender: NSButton) {
            let artistViewModel = artistViewModels[sender.tag]
            artistViewModel.isSelected = sender.state == .on
        }
    }
