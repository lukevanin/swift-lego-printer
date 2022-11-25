import UIKit

import PrintySDK


private let elementSize: CGFloat = 44
private let dotSize: CGFloat = 32


@objc protocol DocumentEditorDelegate {
    @objc optional func documentEditor(_ controller: DocumentEditorViewController, printDocument document: Document)
    @objc optional func documentEditor(_ controller: DocumentEditorViewController, dismissDocument document: Document)
}


final class DocumentEditorViewController: UIViewController {
    
    weak var delegate: DocumentEditorDelegate?

    private let titleLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = UIFont.preferredFont(forTextStyle: .title1)
        return view
    }()

    private let dismissButton: UIButton = {
        var configuration = UIButton.Configuration.borderless()
        configuration.title = "Done"
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
    
    private let printButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Print"
        configuration.image = UIImage(systemName: "printer.dotmatrix")
        configuration.baseBackgroundColor = .systemGreen
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

    private let imageRenderer: ImageRenderer = {
        let configuration = ImageRenderer.Configuration(
            elementSize: CGSize(width: elementSize, height: elementSize),
            dotSize: CGSize(width: dotSize, height: dotSize),
            dotColor: .systemCyan,
            borderColor: .systemCyan,
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
            layout.axis = .horizontal
            layout.spacing = 16
            layout.addArrangedSubview(clearButton)
            layout.addArrangedSubview(printButton)
            return layout
        }()
        
        let mainLayoutView: UIStackView = {
            let layout = UIStackView()
            layout.translatesAutoresizingMaskIntoConstraints = false
            layout.axis = .vertical
            layout.alignment = .center
            layout.distribution = .equalSpacing
            layout.addArrangedSubview(titleLabel)
            layout.addArrangedSubview(canvasImageView)
            layout.addArrangedSubview(buttonsLayoutView)
            return layout
        }()

        view.addSubview(mainLayoutView)
        view.addSubview(dismissButton)
        
        NSLayoutConstraint.activate([
            mainLayoutView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
            mainLayoutView.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor),
            
            mainLayoutView.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor, constant: -64),
            mainLayoutView.heightAnchor.constraint(equalTo: view.layoutMarginsGuide.heightAnchor, constant: -64),

            dismissButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -16),
            dismissButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 16),
        ])
    }
    
    private func setupActions() {

        clearButton.addTarget(self, action: #selector(onClearAction), for: .touchUpInside)
        printButton.addTarget(self, action: #selector(onPrintAction), for: .touchUpInside)
        dismissButton.addTarget(self, action: #selector(onDismissAction), for: .touchUpInside)

        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(onCanvasImageTap))
        canvasImageView.isUserInteractionEnabled = true
        canvasImageView.addGestureRecognizer(imageTapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupImage()
        setupTitle()
    }
    
    // MARK: Actions
    
    @objc func onClearAction(button: UIButton) {
        document.clear()
        invalidateImage()
    }
    
    @objc func onPrintAction(button: UIButton) {
        delegate?.documentEditor?(self, printDocument: document)
    }

    @objc func onDismissAction(button: UIButton) {
        delegate?.documentEditor?(self, dismissDocument: document)
    }

    @objc func onCanvasImageTap(gesture: UITapGestureRecognizer) {
        let image = document.getImage()
        let location = gesture.location(in: canvasImageView)
        let x = Int(((location.x / elementSize) - 0.5).rounded())
        let y = Int(((location.y / elementSize) - 0.5).rounded())
        let oldValue = image.getElement(x: x, y: y)
        let newValue: Image.Element
        switch oldValue {
        case .x:
            newValue = .o
        case .o:
            newValue = .x
        }
        document.setElement(x: x, y: y, value: newValue)
        invalidateImage()
    }
    
    // MARK: Title
    
    private func setupTitle() {
        titleLabel.text = document.localizedName
    }
    
    // MARK: Image
    
    private func setupImage() {
        let imageSize = self.imageSize()
        for constraint in canvasImageView.constraints {
            constraint.isActive = false
        }
        NSLayoutConstraint.activate([
            canvasImageView.widthAnchor.constraint(equalToConstant: imageSize.width),
            canvasImageView.heightAnchor.constraint(equalToConstant: imageSize.height),
        ])
        invalidateImage()
    }
    
    private func imageSize() -> CGSize {
        let image = document.getImage()
        let imageWidth = CGFloat(image.width) * elementSize
        let imageHeight = CGFloat(image.height) * elementSize
        return CGSize(width: imageWidth, height: imageHeight)
    }

    private func invalidateImage() {
        let image = document.getImage()
        let uiImage = imageRenderer.renderImage(image)
        canvasImageView.image = uiImage
    }
}
