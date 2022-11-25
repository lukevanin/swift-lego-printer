//
//  PrinterCalibrationViewController.swift
//  Printy
//
//  Created by Luke Van In on 2022/11/24.
//

import UIKit
import Combine

import SwiftMindstorms

import PrintySDK


private let imagePadding: CGFloat = 32


@objc protocol PrintControllerDelegate {
    @objc optional func printControllerDidCalibrate(_ controller: PrintViewController)
}


final class PrintViewController: UIViewController {
    
    weak var delegate: PrintControllerDelegate?

    private let calibrateButton: UIButton = {
        var configuration = UIButton.Configuration.borderless()
        configuration.title = "Calibrate Printer"
        configuration.image = UIImage(systemName: "target")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let connectButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Connect Printer"
        configuration.image = UIImage(systemName: "wifi")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let stopButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Stop"
        configuration.image = UIImage(systemName: "exclamationmark.octagon")
        configuration.baseBackgroundColor = .systemRed
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let printButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Print"
        configuration.image = UIImage(systemName: "printer.dotmatrix")
        configuration.baseBackgroundColor = .systemGreen
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let previewImageView: UIImageView = {
        var view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .center
        view.layer.cornerRadius = 32
        view.layer.masksToBounds = true
        view.backgroundColor = .white
        return view
    }()
    
    
    private let imageRenderer: ImageRenderer = {
        let configuration = ImageRenderer.Configuration(
            elementSize: CGSize(width: 32, height: 32),
            dotSize: CGSize(width: 30, height: 30),
            dotColor: .systemCyan,
            borderColor: nil,
            backgroundColor: .white
        )
        let renderer = ImageRenderer(configuration: configuration)
        return renderer
    }()
    
    private var printerConnectionStateCancellable: AnyCancellable?
    
    private let document: Document
    private let printer: Printer
    
    init(document: Document, printer: Printer) {
        self.document = document
        self.printer = printer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupView()
        setupActions()
        updatePrinterState(connectionState: .notConnected, printingState: .stopped)
    }
    
    private func setupView() {
        
        navigationItem.title = "Print"
        
        let buttonsLayoutView: UIStackView = {
            let layout = UIStackView()
            layout.translatesAutoresizingMaskIntoConstraints = false
            layout.axis = .horizontal
            layout.spacing = 16
            layout.addArrangedSubview(calibrateButton)
            layout.addArrangedSubview(connectButton)
            layout.addArrangedSubview(printButton)
            layout.addArrangedSubview(stopButton)
            return layout
        }()

        let mainLayoutView: UIStackView = {
            let layout = UIStackView()
            layout.translatesAutoresizingMaskIntoConstraints = false
            layout.axis = .vertical
            layout.alignment = .center
            layout.distribution = .equalSpacing
            layout.addArrangedSubview(previewImageView)
            layout.addArrangedSubview(buttonsLayoutView)
            return layout
        }()

        view.addSubview(mainLayoutView)
        
        NSLayoutConstraint.activate([
            mainLayoutView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
            mainLayoutView.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor),
            mainLayoutView.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor, constant: -64),
            mainLayoutView.heightAnchor.constraint(equalTo: view.layoutMarginsGuide.heightAnchor, constant: -64),
        ])
    }
    
    private func setupActions() {
        
        connectButton.addTarget(self, action: #selector(onConnectAction), for: .touchUpInside)
        
        calibrateButton.addTarget(self, action: #selector(onCalibrateAction), for: .touchUpInside)
        printButton.addTarget(self, action: #selector(onPrintAction), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(onStopAction), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        invalidatePreviewImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        printer.reconnect()
        addPrinterObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removePrinterObserver()
    }
    
    @objc func onConnectAction(button: UIButton) {
        printer.connect()
    }
    
    @objc func onCalibrateAction(button: UIButton) {
        delegate?.printControllerDidCalibrate?(self)
    }

    @objc func onPrintAction(button: UIButton) {
        let image = document.getImage()
        printer.plot(image)
    }
    
    @objc func onStopAction(button: UIButton) {
        printer.stop()
    }
    
    private func invalidatePreviewImage() {
        let image = document.getImage()
        let uiImage = imageRenderer.renderImage(image)
        previewImageView.image = uiImage
        previewImageView.removeConstraints(previewImageView.constraints)
        NSLayoutConstraint.activate([
            previewImageView.widthAnchor.constraint(equalToConstant: uiImage.size.width + imagePadding),
            previewImageView.heightAnchor.constraint(equalToConstant: uiImage.size.height + imagePadding),
        ])
    }
    
    // MARK: Printer state
    
    private func removePrinterObserver() {
        printerConnectionStateCancellable?.cancel()
        printerConnectionStateCancellable = nil
    }
    
    private func addPrinterObserver() {
        printerConnectionStateCancellable = Publishers.CombineLatest(
            printer.connectionStatePublisher,
            printer.printingStatePublisher
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectionState, printingState in
                guard let self = self else {
                    return
                }
                self.updatePrinterState(
                    connectionState: connectionState,
                    printingState: printingState
                )
            }
    }
    
    private func updatePrinterState(
        connectionState: HubConnectionStatus,
        printingState: Printer.PrintingState
    ) {
        let connectButtonEnabled: Bool
        let printButtonEnabled: Bool
        let stopButtonEnabled: Bool
        
        switch (connectionState, printingState) {
        case (.notConnected, _):
            connectButtonEnabled = true
            printButtonEnabled = false
            stopButtonEnabled = false
        case (.connecting, _):
            connectButtonEnabled = false
            printButtonEnabled = false
            stopButtonEnabled = false
        case (.connected, .stopped):
            connectButtonEnabled = false
            printButtonEnabled = true
            stopButtonEnabled = false
        case (.connected, .printing):
            connectButtonEnabled = false
            printButtonEnabled = false
            stopButtonEnabled = true
        }
        connectButton.isHidden = !connectButtonEnabled
        calibrateButton.isHidden = connectButtonEnabled
        calibrateButton.isEnabled = printButtonEnabled
        printButton.isHidden = !printButtonEnabled
        stopButton.isHidden = !stopButtonEnabled
    }
}
