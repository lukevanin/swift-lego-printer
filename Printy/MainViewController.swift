import UIKit


let pixelSize = CGFloat(44)
let pixelInset = CGFloat(8)


final class MainViewController: UIViewController {
    
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

    private let clearButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Clear"
        configuration.image = UIImage(systemName: "xmark.bin")
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
        configuration.image = UIImage(systemName: "arrow.up.and.down")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let xRangeButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "arrow.left.and.right")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let yDecrementButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "arrow.up")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let yIncrementButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "arrow.down")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let xDecrementButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "arrow.left")
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let xIncrementButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
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
    
    private var canvasImageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .center
        view.clipsToBounds = true
        return view
    }()
    
    private var printerImage = Printer.Image.test

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
        
        let canvasButtonsLayoutView: UIStackView = {
            let layout = UIStackView()
            layout.translatesAutoresizingMaskIntoConstraints = false
            layout.axis = .horizontal
            layout.spacing = 16
            layout.addArrangedSubview(clearButton)
            return layout
        }()

        let buttonsLayoutView: UIStackView = {
            let layout = UIStackView()
            layout.translatesAutoresizingMaskIntoConstraints = false
            layout.axis = .horizontal
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
            layout.axis = .vertical
            layout.alignment = .center
            layout.spacing = 32
            layout.addArrangedSubview(buttonsLayoutView)
            layout.addArrangedSubview(canvasImageView)
            layout.addArrangedSubview(canvasButtonsLayoutView)
            return layout
        }()

        view.addSubview(mainLayoutView)
        
        NSLayoutConstraint.activate([
            mainLayoutView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            mainLayoutView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            mainLayoutView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
        ])
        
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

        clearButton.addAction(
            UIAction { [weak self] _ in
                self?.clearImage()
            },
            for: .touchUpInside
        )

        testButton.addAction(
            UIAction { [weak self] _ in
                self?.printer.test()
            },
            for: .touchUpInside
        )

        printButton.addAction(
            UIAction { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.printer.plot(self.printerImage)
            },
            for: .touchUpInside
        )

        stopButton.addAction(
            UIAction { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.printer.stop()
            },
            for: .touchUpInside
        )

        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(onCanvasImageTap))
        canvasImageView.isUserInteractionEnabled = true
        canvasImageView.addGestureRecognizer(imageTapGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        printer.reconnect()
        setupImage()
        invalidateImage()
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

    @objc func onCanvasImageTap(gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: canvasImageView)
        let x = Int(((location.x / pixelSize) - 0.5).rounded())
        let y = Int(((location.y / pixelSize) - 0.5).rounded())
        let oldValue = printerImage.getPixel(x: x, y: y)
        let newValue: Printer.Image.Pixel
        switch oldValue {
        case .x:
            newValue = .o
        case .o:
            newValue = .x
        }
        printerImage.setPixel(x: x, y: y, value: newValue)
        invalidateImage()
    }
    
    private func setupImage() {
        let imageSize = self.imageSize()
        for constraint in canvasImageView.constraints {
            constraint.isActive = false
        }
        NSLayoutConstraint.activate([
            canvasImageView.widthAnchor.constraint(equalToConstant: imageSize.width),
            canvasImageView.heightAnchor.constraint(equalToConstant: imageSize.height),
        ])
    }
    
    private func clearImage() {
        printerImage.clear()
        invalidateImage()
    }
    
    private func invalidateImage() {
        let size = imageSize()
        let bounds = CGRect(origin: .zero, size: size)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(bounds)
            for y in 0 ..< printerImage.height {
                for x in 0 ..< printerImage.width {
                    let pixel = printerImage.getPixel(x: x, y: y)
                    let pixelBounds = CGRect(
                        x: CGFloat(x) * pixelSize,
                        y: CGFloat(y) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    let fillBounds = pixelBounds.insetBy(dx: pixelInset, dy: pixelInset)
                    let borderBounds = pixelBounds.insetBy(dx: 1, dy: 1)
                    
                    UIColor.systemCyan.setFill()
                    context.fill(pixelBounds)

                    UIColor.white.setFill()
                    context.fill(borderBounds)

                    
                    let color: UIColor
                    switch pixel {
                    case .x:
                        color = .systemCyan
                    case .o:
                        color = .white
                    }
                    color.setFill()
                    context.fill(fillBounds)
                    
                }
            }
        }
        canvasImageView.image = image
    }
    
    private func imageSize() -> CGSize {
        let imageWidth = CGFloat(printerImage.width) * pixelSize
        let imageHeight = CGFloat(printerImage.height) * pixelSize
        return CGSize(width: imageWidth, height: imageHeight)
    }
}

