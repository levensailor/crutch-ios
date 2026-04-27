import UIKit
import SwiftUI

class PageTurnerHandler: ObservableObject {
    @Published var currentPage: Int = 0
    var totalPages: Int = 0
    var onPageChange: ((Int) -> Void)?
    
    func goToNextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
            onPageChange?(currentPage)
        }
    }
    
    func goToPreviousPage() {
        if currentPage > 0 {
            currentPage -= 1
            onPageChange?(currentPage)
        }
    }
}

// UIViewController wrapper for handling key commands
struct KeyCommandHandler: UIViewControllerRepresentable {
    let onUpArrow: () -> Void
    let onDownArrow: () -> Void
    
    func makeUIViewController(context: Context) -> KeyCommandViewController {
        let controller = KeyCommandViewController()
        controller.onUpArrow = onUpArrow
        controller.onDownArrow = onDownArrow
        return controller
    }
    
    func updateUIViewController(_ uiViewController: KeyCommandViewController, context: Context) {
        uiViewController.onUpArrow = onUpArrow
        uiViewController.onDownArrow = onDownArrow
    }
}

class KeyCommandViewController: UIViewController {
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    
    override var canBecomeFirstResponder: Bool { true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for app going to background to resign first responder
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Ensure we're not first responder when view disappears
        if isFirstResponder {
            resignFirstResponder()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if isFirstResponder {
            resignFirstResponder()
        }
    }
    
    @objc private func applicationDidEnterBackground() {
        if isFirstResponder {
            resignFirstResponder()
        }
    }
    
    @objc private func applicationWillResignActive() {
        if isFirstResponder {
            resignFirstResponder()
        }
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(handleUpArrow)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(handleDownArrow))
        ]
    }
    
    @objc func handleUpArrow() {
        onUpArrow?()
    }
    
    @objc func handleDownArrow() {
        onDownArrow?()
    }
}


