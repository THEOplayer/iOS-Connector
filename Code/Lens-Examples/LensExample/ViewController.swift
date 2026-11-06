//
//  ViewController.swift
//  LensExample
//

import LensSDK
import THEOplayerConnectorLens
import THEOplayerSDK
import UIKit

class ViewController: UIViewController {
    private let player: THEOplayer = {
        let configuration = THEOplayerConfigurationBuilder()
        configuration.license = theoplayerLicense
        return THEOplayer(configuration: configuration.build())
    }()
    private var lensConnector: LensConnector?
    private let playerContainer = UIView()
    private let sessionLabel = UILabel()
    private var sessionTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layout()
        player.addAsSubview(of: playerContainer)

        do {
            try Lens.configure(LensConfigureOptions(backend: .disabled))
            lensConnector = try LensConnector(
                player: player,
                configuration: LensConfiguration(
                    destinations: lensDestinationUrl.map { [LensDestination(url: $0, format: .json)] } ?? []
                )
            )
        } catch {
            sessionLabel.text = "Lens: \(error)"
        }
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.showSession()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        player.frame = playerContainer.bounds
    }

    deinit {
        sessionTimer?.invalidate()
        lensConnector?.destroy()
    }

    private func showSession() {
        guard let lensConnector else { return }
        sessionLabel.text = lensConnector.handle.session.map { "Lens session \($0.sessionId)" } ?? "No Lens session: press play"
    }

    private func load(_ src: String) {
        player.source = SourceDescription(source: TypedSource(src: src, type: "application/x-mpegurl"))
    }

    private func layout() {
        let buttons = exampleSources.map { source in
            UIButton(
                configuration: .bordered(),
                primaryAction: UIAction(title: source.title) { [weak self] _ in self?.load(source.src) }
            )
        }
        let controls = [
            UIButton(configuration: .filled(), primaryAction: UIAction(title: "Play") { [weak self] _ in self?.player.play() }),
            UIButton(configuration: .filled(), primaryAction: UIAction(title: "Pause") { [weak self] _ in self?.player.pause() }),
            UIButton(configuration: .filled(), primaryAction: UIAction(title: "Stop") { [weak self] _ in self?.player.stop() }),
        ]
        let controlRow = UIStackView(arrangedSubviews: controls)
        controlRow.distribution = .fillEqually
        controlRow.spacing = 8
        sessionLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        sessionLabel.numberOfLines = 0

        playerContainer.backgroundColor = .black
        let stack = UIStackView(arrangedSubviews: [playerContainer, controlRow] + buttons + [sessionLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            playerContainer.heightAnchor.constraint(equalTo: playerContainer.widthAnchor, multiplier: 9.0 / 16.0),
        ])
    }
}
