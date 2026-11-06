//
//  ViewController.swift
//  LensExample
//

import LensSDK
import THEOplayerConnectorLens
import THEOplayerSDK
import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let player: THEOplayer = {
        let configuration = THEOplayerConfigurationBuilder()
        configuration.license = theoplayerLicense
        return THEOplayer(configuration: configuration.build())
    }()
    private var lensConnector: LensConnector?
    private let playerContainer = UIView()
    private let sessionLabel = UILabel()
    private let reportsTable = UITableView(frame: .zero, style: .plain)
    private var reports: [[String: Any]] = []
    private var sessionTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layout()
        player.addAsSubview(of: playerContainer)

        LensReceiver.onReport = { [weak self] in self?.received($0) }
        LensReceiver.start()
        let destinations = ([LensReceiver.url] + [lensDestinationUrl].compactMap { $0 }).map {
            LensDestination(url: $0, format: .json, heartbeat: true)
        }
        do {
            try Lens.configure(LensConfigureOptions(backend: .disabled))
            lensConnector = try LensConnector(
                player: player,
                configuration: LensConfiguration(destinations: destinations, heartbeatMs: 10_000)
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

    // MARK: Player

    private func load(_ src: String) {
        let type = src.lowercased().contains(".m3u8") ? "application/x-mpegurl" : "video/mp4"
        player.source = SourceDescription(source: TypedSource(src: src, type: type))
    }

    private func askForUrl() {
        let alert = UIAlertController(title: "Custom URL", message: "Your THEOplayer license must allow its domain.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "https://…/stream.m3u8"; $0.keyboardType = .URL }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Load", style: .default) { [weak self, weak alert] _ in
            if let src = alert?.textFields?.first?.text, !src.isEmpty { self?.load(src) }
        })
        present(alert, animated: true)
    }

    private func showSession() {
        guard let lensConnector else { return }
        sessionLabel.text = lensConnector.handle.session.map { "Lens session \($0.sessionId)" } ?? "No Lens session: load a source and play"
    }

    // MARK: Reports

    private func received(_ report: [String: Any]) {
        reports.insert(report, at: 0)
        reportsTable.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reports.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "report") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "report")
        let report = reports[indexPath.row]
        cell.textLabel?.text = ReportFormat.title(report)
        cell.textLabel?.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        cell.detailTextLabel?.text = ReportFormat.details(report)
        cell.detailTextLabel?.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 0
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alert = UIAlertController(title: ReportFormat.title(reports[indexPath.row]), message: ReportFormat.json(reports[indexPath.row]), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: Layout

    private func button(_ title: String, _ style: UIButton.Configuration = .bordered(), action: @escaping (UIButton) -> Void) -> UIButton {
        UIButton(configuration: style, primaryAction: UIAction(title: title) { action($0.sender as! UIButton) })
    }

    private func row(_ views: [UIView]) -> UIStackView {
        let row = UIStackView(arrangedSubviews: views)
        row.distribution = .fillEqually
        row.spacing = 8
        return row
    }

    private func layout() {
        let sources = UIButton(configuration: .filled())
        sources.setTitle("Load a source", for: .normal)
        sources.showsMenuAsPrimaryAction = true
        sources.menu = UIMenu(children: exampleSources.map { source in
            UIAction(title: source.title) { [weak self] _ in self?.load(source.src) }
        } + [UIAction(title: "Custom URL…") { [weak self] _ in self?.askForUrl() }])

        let controls = [
            row([sources, button("Stop") { [weak self] _ in self?.player.stop() }]),
            row([
                button("Play", .filled()) { [weak self] _ in self?.player.play() },
                button("Pause", .filled()) { [weak self] _ in self?.player.pause() },
                button("+30 s") { [weak self] _ in
                    guard let player = self?.player else { return }
                    player.currentTime += 30
                },
            ]),
            row([
                button("Mute") { [weak self] sender in
                    guard let player = self?.player else { return }
                    player.muted.toggle()
                    sender.configuration?.title = player.muted ? "Unmute" : "Mute"
                },
                button("Rate 2×") { [weak self] sender in
                    guard let player = self?.player else { return }
                    player.playbackRate = player.playbackRate == 1 ? 2 : 1
                    sender.configuration?.title = player.playbackRate == 1 ? "Rate 2×" : "Rate 1×"
                },
                button("Fullscreen") { [weak self] _ in self?.player.presentationMode = .fullscreen },
            ]),
        ]

        sessionLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        sessionLabel.numberOfLines = 0
        let reportsHeader = UILabel()
        reportsHeader.text = "Reports Lens sent, newest first (tap for all keys)"
        reportsHeader.font = .preferredFont(forTextStyle: .footnote)
        reportsHeader.textColor = .secondaryLabel
        let clear = button("Clear") { [weak self] _ in
            self?.reports = []
            self?.reportsTable.reloadData()
        }
        clear.setContentHuggingPriority(.required, for: .horizontal)
        let header = UIStackView(arrangedSubviews: [reportsHeader, clear])
        reportsTable.dataSource = self
        reportsTable.delegate = self

        playerContainer.backgroundColor = .black
        let stack = UIStackView(arrangedSubviews: [playerContainer] + controls + [sessionLabel, header, reportsTable])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(12, after: playerContainer)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            playerContainer.heightAnchor.constraint(equalTo: playerContainer.widthAnchor, multiplier: 9.0 / 16.0),
        ])
    }
}

/// Short, readable lines for a Lens report.
private enum ReportFormat {
    static let events = [
        "t": "heartbeat", "ps": "state change", "e": "error", "bc": "bitrate change", "m": "mute", "um": "unmute",
        "pr": "rate change", "b": "background change", "pe": "player expanded", "pc": "player collapsed",
        "c": "content ID change", "h": "hostname change", "ce": "custom event",
    ]
    static let states = [
        "d": "preloading", "s": "starting", "p": "playing", "k": "seeking", "r": "rebuffering", "a": "paused",
        "w": "waiting for input", "e": "ended", "f": "fatal error", "q": "quit",
    ]
    /// The keys worth a glance; the rest is one tap away.
    static let highlighted = ["cid", "st", "sf", "pt", "bl", "tbl", "br", "pb", "tb", "lb", "ab", "tab", "lab", "mtp", "dfa", "pr", "ec", "su", "bg"]

    static func title(_ report: [String: Any]) -> String {
        let event = report["e"] as? String ?? "?"
        let state = (report["sta"] as? String).map { " · \(states[$0] ?? $0)" } ?? ""
        return "[\(report["ns"] as? String ?? "?")] \(events[event] ?? event)\(state)"
    }

    static func details(_ report: [String: Any]) -> String {
        highlighted.compactMap { key in report[key].map { "\(key)=\(value($0))" } }.joined(separator: "  ")
    }

    static func json(_ report: [String: Any]) -> String {
        report.keys.sorted().map { "\($0) = \(value(report[$0]!))" }.joined(separator: "\n")
    }

    private static func value(_ value: Any) -> String {
        if let items = value as? [[String: Any]] {
            return "(" + items.map { item in (item["ot"].map { "\($0):" } ?? "") + "\(item["value"] ?? "")" }.joined(separator: " ") + ")"
        }
        return "\(value)"
    }
}
