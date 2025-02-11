//
//  PlayerInterfaceView.swift
//
//  Copyright © 2024 THEOPlayer. All rights reserved.
//

import UIKit

// MARK: - PlayerInterfaceViewDelegate declaration

protocol PlayerInterfaceViewDelegate: AnyObject {
    func play()
    func pause()
    func skip(isForward: Bool)
    func seek(timeInSeconds: Float)
}

// MARK: - PlayerInterfaceViewState enumeration declaration

enum PlayerInterfaceViewState: Int {
    case initialise
    case buffering
    case playing
    case paused
    case adplaying
    case adpaused
}

// MARK: - PlayerInterfaceView declaration

class PlayerInterfaceView: UIView {

    // MARK: - Private properties

    private var containerView: UIView!
    private var controllerStackView: UIStackView!
    private var footerView: UIView!
    private var activityIndicatorView: UIActivityIndicatorView!
    private var playButton: UIButton!
    private var pauseButton: UIButton!
    private var skipBackwardButton: UIButton!
    private var skipForwardButton: UIButton!
    private var slider: UISlider!
    private var progressLabel: UILabel!

    // Boolean flag to show/hide the interface
    private var isInterfaceShowing: Bool {
        return state == .initialise || !containerView.isHidden
    }
    private var isOverHourLong: Bool = false
    private var isDraggingSlider: Bool = false
    private var durationString: String = "00:00"
    private var currentTimeString: String = "00:00" {
        didSet {
            // Update progress label when curent time string is set
            progressLabel.text = "\(currentTimeString) / \(durationString)"
        }
    }

    // Public properties

    // Display corresponding UI components based on the view state
    var state: PlayerInterfaceViewState! {
        didSet {
            activityIndicatorView.stopAnimating()
            playButton.isHidden = true
            pauseButton.isHidden = true
            skipBackwardButton.isHidden = true
            skipForwardButton.isHidden = true
            footerView.isHidden = true
            slider.isEnabled = true
            switch state {
            case .initialise:
                containerView.isHidden = false
                currentTime = 0.0
                playButton.isHidden = false
                isDraggingSlider = false
            case .buffering:
                containerView.isHidden = false
                activityIndicatorView.startAnimating()
                skipBackwardButton.isHidden = false
                skipForwardButton.isHidden = false
                footerView.isHidden = false
            case .playing:
                pauseButton.isHidden = false
                skipBackwardButton.isHidden = false
                skipForwardButton.isHidden = false
                footerView.isHidden = false
            case .paused:
                playButton.isHidden = false
                skipBackwardButton.isHidden = false
                skipForwardButton.isHidden = false
                footerView.isHidden = false
            case .adplaying:
                pauseButton.isHidden = false
                footerView.isHidden = false
                slider.isEnabled = false
            case .adpaused:
                playButton.isHidden = false
                footerView.isHidden = false
                slider.isEnabled = false
            default:
                break
            }
        }
    }
    var duration: Float = 0.0 {
        didSet {
            // Set duration as the slider maximum value
            slider.maximumValue = duration

            isOverHourLong = (duration / 3600) >= 1
            durationString = convertTimeString(time: duration)
        }
    }
    var currentTime: Float = 0.0 {
        didSet {
            if !isDraggingSlider {
                // Update slider value
                slider.value = currentTime

                currentTimeString = convertTimeString(time: currentTime)
            }
        }
    }
    weak var delegate: PlayerInterfaceViewDelegate? = nil

    // MARK: - View life cycle

    init() {
        super.init(frame: .zero)

        setupView()
        setupContainerView()
        setupControllerStackView()
        setupControllerStackViewItems()
        setupFooterView()
        setupTransparentSubview()
        setupSlider()
        setupProgressLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setConstraintsToSafeArea(safeArea: UILayoutGuide) {
        // Position PlayerInterfaceView at the center of the safe area
        self.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor).isActive = true
        // Set width and height using the width and height of the safe area
        self.widthAnchor.constraint(equalTo: safeArea.widthAnchor).isActive = true
        self.heightAnchor.constraint(equalTo: safeArea.heightAnchor).isActive = true
    }

    // MARK: - View setup

    private func setupView() {
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupContainerView() {
        containerView = THEOComponent.view()

        self.addSubview(containerView)
        containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    private func setupControllerStackView() {
        controllerStackView = THEOComponent.stackView(axis: .horizontal, spacing: 40)
        controllerStackView.alignment = .center

        containerView.addSubview(controllerStackView)
        controllerStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        controllerStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        controllerStackView.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor).isActive = true
        controllerStackView.heightAnchor.constraint(lessThanOrEqualTo: containerView.heightAnchor, multiplier: 0.6).isActive = true
    }

    private func setupButton(imageName: String, isLarge: Bool) -> UIButton {
        let button = THEOComponent.button(text: nil, image: UIImage(named: imageName))
        button.backgroundColor = .clear

        controllerStackView.addArrangedSubview(button)
        button.widthAnchor.constraint(equalTo: button.heightAnchor).isActive = true
        button.widthAnchor.constraint(equalToConstant: isLarge ? 100 : 60).isActive = true

        return button
    }

    private func setupActivityIndicatorView() {
        activityIndicatorView = UIActivityIndicatorView(style: .large)

        controllerStackView.addArrangedSubview(activityIndicatorView)
        activityIndicatorView.widthAnchor.constraint(equalTo: activityIndicatorView.heightAnchor).isActive = true
        activityIndicatorView.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }

    private func setupControllerStackViewItems() {
        skipBackwardButton = setupButton(imageName: "skip-backward", isLarge: false)
        skipBackwardButton.addTarget(self, action: #selector(onSkipBackward), for: .touchUpInside)

        setupActivityIndicatorView()

        playButton = setupButton(imageName: "play", isLarge: true)
        playButton.addTarget(self, action: #selector(onPlay), for: .touchUpInside)

        pauseButton = setupButton(imageName: "pause", isLarge: true)
        pauseButton.addTarget(self, action: #selector(onPause), for: .touchUpInside)

        skipForwardButton = setupButton(imageName: "skip-forward", isLarge: false)
        skipForwardButton.addTarget(self, action: #selector(onSkipForward), for: .touchUpInside)
    }

    private func setupFooterView() {
        footerView = THEOComponent.view()
        footerView.backgroundColor = .clear
        footerView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        containerView.addSubview(footerView)
        footerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        footerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        footerView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        footerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    private func setupTransparentSubview() {
        let view = THEOComponent.view()
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)

        footerView.addSubview(view)
        view.leadingAnchor.constraint(equalTo: footerView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: footerView.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: footerView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: footerView.bottomAnchor).isActive = true
    }

    private func setupSlider() {
        slider = THEOComponent.slider()
        // Add callback to monitor valueChanged
        slider.addTarget(self, action: #selector(onSliderValueChange), for: .valueChanged)
        // Add tap gesture recognizer to the slider to support tap to set value
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onSliderTapped))
        slider.addGestureRecognizer(tapGestureRecognizer)

        footerView.addSubview(slider)
        let layoutMarginsGuide = footerView.layoutMarginsGuide
        slider.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        slider.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        slider.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
    }

    private func setupProgressLabel() {
        progressLabel = THEOComponent.label(text: "00:00 / 00:00")
        progressLabel.textColor = .theoWhite
        progressLabel.textAlignment = .center

        footerView.addSubview(progressLabel)
        progressLabel.widthAnchor.constraint(equalToConstant: 130).isActive = true
        let layoutMarginsGuide = footerView.layoutMarginsGuide
        progressLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        progressLabel.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor).isActive = true
        progressLabel.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 10).isActive = true
    }

    // MARK: - Util function to convert time string

    private func convertTimeString(time: Float) -> String {
        let seconds = Int(time)
        let (hour, mim, sec) = ((seconds / 3600), ((seconds % 3600) / 60), ((seconds % 3600) % 60))

        if isOverHourLong {
            return String(format: "%02d:%02d:%02d", hour, mim, sec)
        } else {
            return String(format: "%02d:%02d", mim, sec)
        }
    }

    // MARK: - Gesture callback

    @objc private func onTapped(sender: UITapGestureRecognizer) {
        // Placeholder. All tap logics are handled in the shouldReceive callback of gestureRecognizer
    }

    // MARK: - Button callbacks

    @objc private func onSkipBackward() {
        delegate?.skip(isForward: false)
    }

    @objc private func onPlay() {
        delegate?.play()
    }

    @objc private func onPause() {
        delegate?.pause()
    }

    @objc private func onSkipForward() {
        delegate?.skip(isForward: true)
    }

    // MARK: - Slider callbacks

    @objc private func onSliderTapped(gestureRecognizer: UIGestureRecognizer) {
        let tappedPoint: CGPoint = gestureRecognizer.location(in: self)
        let xOffset: CGFloat = tappedPoint.x - slider.frame.origin.x
        var tappedValue: Float = 0.0
        // X offset can not be smaller than 0
        if xOffset > 0 {
            // Multiply current X offset to the 'max value' : 'width' ratio to work out the tapped value
            tappedValue = Float((xOffset * CGFloat(slider.maximumValue) / slider.frame.size.width))
        }

        slider.setValue(tappedValue, animated: true)
        delegate?.seek(timeInSeconds: tappedValue)
    }

    @objc private func onSliderValueChange(slider: UISlider, event: UIEvent) {
        if let touch = event.allTouches?.first {
            switch touch.phase {
            case .began:
                isDraggingSlider = true
            case .moved:
                // Update time label to reflect the dragged time
                currentTimeString = convertTimeString(time: slider.value)
            case .ended:
                isDraggingSlider = false
                delegate?.seek(timeInSeconds: slider.value)
            default:
                break
            }
        }
    }
}
