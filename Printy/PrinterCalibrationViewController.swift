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


final class PrinterCalibrationViewController: UIViewController {
    
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
    
    private var printerConnectionStateCancellable: AnyCancellable?
    
    private let printer: Printer
    
    init(printer: Printer) {
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
            layout.addArrangedSubview(stopButton)
            return layout
        }()

        let mainLayoutView: UIStackView = {
            let layout = UIStackView()
            layout.translatesAutoresizingMaskIntoConstraints = false
            layout.axis = .horizontal
            layout.spacing = 16
            layout.addArrangedSubview(buttonsLayoutView)
            return layout
        }()

        view.addSubview(mainLayoutView)
        
        NSLayoutConstraint.activate([
            mainLayoutView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
            mainLayoutView.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor),
        ])
    }
    
    private func setupActions() {
        
        // Button actions

        connectButton.addTarget(self, action: #selector(onConnectAction), for: .touchUpInside)

        homeButton.addTarget(self, action: #selector(onHomeAction), for: .touchUpInside)
        
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

        testButton.addTarget(self, action: #selector(onTestAction), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(onStopAction), for: .touchUpInside)
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
    
    // MARK: Actions
    
    @objc func onHomeAction(button: UIButton) {
        printer.home()
    }
    
    @objc func onConnectAction(button: UIButton) {
        printer.connect()
    }
    
    @objc func onTestAction(button: UIButton) {
        printer.test()
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
        let moveButtonsEnabled: Bool
        
        switch (connectionState, printingState) {
        case (.notConnected, _):
            connectButtonEnabled = true
            printButtonEnabled = false
            stopButtonEnabled = false
            moveButtonsEnabled = false
        case (.connecting, _):
            connectButtonEnabled = false
            printButtonEnabled = false
            stopButtonEnabled = false
            moveButtonsEnabled = false
        case (.connected, .stopped):
            connectButtonEnabled = false
            printButtonEnabled = true
            stopButtonEnabled = false
            moveButtonsEnabled = true
        case (.connected, .printing):
            connectButtonEnabled = false
            printButtonEnabled = false
            stopButtonEnabled = true
            moveButtonsEnabled = true
        }
        
        connectButton.isHidden = !connectButtonEnabled
        homeButton.isHidden = !moveButtonsEnabled
        xIncrementButton.isHidden = !moveButtonsEnabled
        xDecrementButton.isHidden = !moveButtonsEnabled
        yIncrementButton.isHidden = !moveButtonsEnabled
        yDecrementButton.isHidden = !moveButtonsEnabled
        xRangeButton.isHidden = !moveButtonsEnabled
        yRangeButton.isHidden = !moveButtonsEnabled
        testButton.isHidden = !printButtonEnabled
        stopButton.isHidden = !stopButtonEnabled
    }

}
