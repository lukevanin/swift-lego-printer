import UIKit
import OSLog
import UniformTypeIdentifiers

import PrintySDK


private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "App")


@main
class AppDelegate: UIResponder {
    
    var window: UIWindow?
    
    lazy var documentBrowserViewController: DocumentBrowserViewController = {
        return DocumentBrowserViewController()
    }()
    
    lazy var printer: Printer = {
        let configuration = Printer.Configuration(
            xAxis: Printer.Configuration.GearAxis(
                motor: Printer.Configuration.Motor(
                    port: .C,
                    speed: 100
                ),
                ratio: 24,
                camLength: Measurement(value: 8, unit: .millimeters),
                resolution: Measurement(value: 180, unit: .degrees),
                backlash: Measurement(value: 50, unit: .degrees)
            ),
            yAxis: Printer.Configuration.GearAxis(
                motor: Printer.Configuration.Motor(
                    port: .E,
                    speed: 100
                ),
                ratio: 24,
                camLength: Measurement(value: 8, unit: .millimeters),
                resolution: Measurement(value: 180, unit: .degrees),
                backlash: Measurement(value: 50, unit: .degrees)
            ),
            penAxis: Printer.Configuration.CamAxis(
                motor: Printer.Configuration.Motor(
                    port: .A,
                    speed: 30
                ),
                camLength: Measurement(value: 8, unit: .millimeters),
                startAngle: Measurement(value: 290, unit: .degrees),
                endAngle: Measurement(value: 330, unit: .degrees),
                backlashAngle: Measurement(value: 0, unit: .degrees)
            )
        )
        let printer = Printer(configuration: configuration)
        return printer
    }()
    
    private func presentDocument(at documentURL: URL) {
        logger.debug("Presenting document \(documentURL)")
        Task {
            let document = Document(fileURL: documentURL)
            let opened = await document.open()
            guard opened == true else {
                logger.warning("Cannot open document \(documentURL)")
                return
            }
            let viewController = DocumentEditorViewController(
                document: document
            )
            viewController.delegate = self
            
            presentViewController(viewController, from: documentBrowserViewController, modalPresentationStyle: .pageSheet) {
                document.autosave()
            }
        }
    }
    
    private func presentViewController(
        _ viewController: UIViewController,
        from presentingViewController: UIViewController,
        modalPresentationStyle: UIModalPresentationStyle = .formSheet,
        onDismiss: (() -> Void)? = nil
    ) {
        let dismissButton = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak presentingViewController] _ in
                onDismiss?()
                presentingViewController?.dismiss(animated: true)
            }
        )
        viewController.navigationItem.rightBarButtonItem = dismissButton
        
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = modalPresentationStyle
        presentingViewController.present(navigationController, animated: true, completion: nil)
    }
}

extension AppDelegate: DocumentEditorControllerDelegate {
    
    func documentEditorController(_ controller: DocumentEditorViewController, printDocument document: Document) {
        logger.info("Print document")
        let viewController = PrintViewController(
            document: document,
            printer: printer
        )
        viewController.delegate = self
        presentViewController(viewController, from: controller)
    }
}

extension AppDelegate: PrintControllerDelegate {
    
    func printControllerDidCalibrate(_ controller: PrintViewController) {
        logger.info("Calibrate")
        let viewController = PrinterCalibrationViewController(printer: printer)
        presentViewController(viewController, from: controller)
    }
}

extension AppDelegate: UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        application.isIdleTimerDisabled = true
        documentBrowserViewController.delegate = self
        let window = UIWindow()
        window.rootViewController = documentBrowserViewController
        window.makeKeyAndVisible()
        self.window = window
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
}

#warning("TODO: Implement UIDocumentBrowserViewControllerDelegate in a Coordinator")

extension AppDelegate: UIDocumentBrowserViewControllerDelegate {
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        Task {
            logger.debug("Creating new document")
            
            let directoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let fileURL = directoryURL.appendingPathComponent("Document", conformingTo: Document.uti)
            
            let document = Document(fileURL: fileURL)
            
            let saved = await document.save(to: fileURL, for: .forCreating)
            
            guard saved == true else {
                logger.warning("Cannot save new document")
                importHandler(nil, .none)
                return
            }
            
            let closed = await document.close()
            
            guard closed == true else {
                logger.warning("Cannot close new document")
                importHandler(nil, .none)
                return
            }
            
            importHandler(fileURL, .move)
        }
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        logger.debug("Import document from \(sourceURL) to \(destinationURL)")
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        logger.debug("Pick document at \(documentURLs)")
        guard let documentURL = documentURLs.first else {
            return
        }
        presentDocument(at: documentURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        logger.warning("Cannot import document from \(documentURL). Reason: \(error?.localizedDescription ?? "Unknown")")
    }
}
