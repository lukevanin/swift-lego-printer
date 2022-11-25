//
//  PrinterCalibrationViewController.swift
//  Printy
//
//  Created by Luke Van In on 2022/11/24.
//

import UIKit

import PrintySDK


final class PrintViewController: UIViewController {
    
    private let dismissButton: UIButton = {
        var configuration = UIButton.Configuration.borderless()
        configuration.title = "Done"
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let testButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Test"
        configuration.image = UIImage(systemName: "squareshape.split.2x2.dotted")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let yRangeButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Y Range"
        configuration.image = UIImage(systemName: "arrow.up.and.down")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let xRangeButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "X Range"
        configuration.image = UIImage(systemName: "arrow.left.and.right")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let yDecrementButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Move -Y"
        configuration.image = UIImage(systemName: "arrow.up")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let yIncrementButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Move +Y"
        configuration.image = UIImage(systemName: "arrow.down")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let xDecrementButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Move -X"
        configuration.image = UIImage(systemName: "arrow.left")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let xIncrementButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Move +X"
        configuration.image = UIImage(systemName: "arrow.right")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let homeButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Home"
        configuration.image = UIImage(systemName: "target")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let connectButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Connect"
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
        view.contentMode = .scaleAspectFit
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
    }
    
    private func setupView() {
        
        let buttonsLayoutView: UIStackView = {
            let layout = UIStackView()
            layout.translatesAutoresizingMaskIntoConstraints = false
            layout.axis = .vertical
            layout.spacing = 16
            layout.addArrangedSubview(connectButton)
            layout.addArrangedSubview(homeButton)
            layout.addArrangedSubview(xDecrementButton)
            layout.addArrangedSubview(xIncrementButton)
            layout.addArrangedSubview(yDecrementButton)
            layout.addArrangedSubview(yIncrementButton)
            layout.addArrangedSubview(xRangeButton)
            layout.addArrangedSubview(yRangeButton)
            layout.addArrangedSubview(testButton)
            layout.addArrangedSubview(printButton)
            layout.addArrangedSubview(stopButton)
            return layout
        }()

        let mainLayoutView: UIStackView = {
            let layout = UIStackView()
            layout.translatesAutoresizingMaskIntoConstraints = false
            layout.axis = .horizontal
            layout.spacing = 16
            layout.addArrangedSubview(previewImageView)
            layout.addArrangedSubview(buttonsLayoutView)
            return layout
        }()

        view.addSubview(mainLayoutView)
        view.addSubview(dismissButton)
        
        NSLayoutConstraint.activate([
            mainLayoutView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
            mainLayoutView.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor),
            
            dismissButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -16),
            dismissButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 16),
        ])
    }
    
    private func setupActions() {
        
        // Button actions

        connectButton.addAction(
            UIAction { [weak self] _ in
                self?.printer.connect()
            },
            for: .touchUpInside
        )

        homeButton.addAction(
            UIAction { [weak self] _ in
                self?.printer.home()
            },
            for: .touchUpInside
        )
        
        xIncrementButton.addTarget(self, action: #selector(onXAxisIncrementStartAction), for: .touchDown)
        xIncrementButton.addTarget(self, action: #selector(onXAxisStopAction), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        xDecrementButton.addTarget(self, action: #selector(onXAxisDecrementStartAction), for: .touchDown)
        xDecrementButton.addTarget(self, action: #selector(onXAxisStopAction), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        yIncrementButton.addTarget(self, action: #selector(onYAxisIncrementStartAction), for: .touchDown)
        yIncrementButton.addTarget(self, action: #selector(onYAxisStopAction), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        yDecrementButton.addTarget(self, action: #selector(onYAxisDecrementStartAction), for: .touchDown)
        yDecrementButton.addTarget(self, action: #selector(onYAxisStopAction), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        xRangeButton.addTarget(self, action: #selector(onXRangeAction), for: .touchUpInside)
        yRangeButton.addTarget(self, action: #selector(onYRangeAction), for: .touchUpInside)
        
        dismissButton.addTarget(self, action: #selector(onDismissAction), for: .touchUpInside)

        testButton.addTarget(self, action: #selector(onTestAction), for: .touchUpInside)
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
    }
    
    @objc func onDismissAction(button: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func onTestAction(button: UIButton) {
        printer.test()
    }
    
    @objc func onPrintAction(button: UIButton) {
        let image = document.getImage()
        printer.plot(image)
    }
    
    @objc func onStopAction(button: UIButton) {
        printer.stop()
    }

    @objc func onXAxisIncrementStartAction(button: UIButton) {
        printer.controlXAxis(direction: +1)
    }
        
    @objc func onXAxisDecrementStartAction(button: UIButton) {
        printer.controlXAxis(direction: -1)
    }
    
    @objc func onXAxisStopAction(button: UIButton) {
        printer.controlXAxis(direction: 0)
    }
    
    @objc func onYAxisIncrementStartAction(button: UIButton) {
        printer.controlYAxis(direction: +1)
    }
        
    @objc func onYAxisDecrementStartAction(button: UIButton) {
        printer.controlYAxis(direction: -1)
    }
    
    @objc func onYAxisStopAction(button: UIButton) {
        printer.controlYAxis(direction: 0)
    }
    
    @objc func onXRangeAction(button: UIButton) {
        printer.rangeXAxis()
    }
    
    @objc func onYRangeAction(button: UIButton) {
        printer.rangeYAxis()
    }
    
    private func invalidatePreviewImage() {
        let image = document.getImage()
        let uiImage = imageRenderer.renderImage(image)
        previewImageView.image = uiImage
    }
}
