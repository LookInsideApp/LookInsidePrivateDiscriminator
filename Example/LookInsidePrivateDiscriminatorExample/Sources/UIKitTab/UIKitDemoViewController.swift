import UIKit

final class UIKitDemoViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "UIKit"
        view.backgroundColor = .systemGroupedBackground
        configureScrollView()
        configureContent()
    }

    private func configureScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])
    }

    private func configureContent() {
        stackView.addArrangedSubview(HeaderView())

        let bodyCard = UIView()
        bodyCard.backgroundColor = .secondarySystemGroupedBackground
        bodyCard.layer.cornerRadius = 14
        bodyCard.layer.cornerCurve = .continuous
        bodyCard.translatesAutoresizingMaskIntoConstraints = false

        let bodyLabel = UILabel()
        bodyLabel.text = "Inspect this screen to exercise basename-derived private discriminator lookups."
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyCard.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            bodyLabel.leadingAnchor.constraint(equalTo: bodyCard.leadingAnchor, constant: 18),
            bodyLabel.trailingAnchor.constraint(equalTo: bodyCard.trailingAnchor, constant: -18),
            bodyLabel.topAnchor.constraint(equalTo: bodyCard.topAnchor, constant: 18),
            bodyLabel.bottomAnchor.constraint(equalTo: bodyCard.bottomAnchor, constant: -18),
        ])

        stackView.addArrangedSubview(bodyCard)
        stackView.addArrangedSubview(FooterView())
    }
}
