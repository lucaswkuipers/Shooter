import Foundation
import GameController
import CoreHaptics

protocol HapticsManagerDelegate: AnyObject {
    func didConnect(controller: GCController)
    func didDisconnectController()
}

class HapticsManager {

    private var isSetup = false

    private var controller: GCController?
    // A haptic engine manages the connection to the haptic server.
    private var engineMap = [GCHapticsLocality: CHHapticEngine]()

    weak var delegate: HapticsManagerDelegate? {
        didSet {
            if delegate != nil {
                startObserving()
            }
        }
    }

    /// - Tag: StartObserving
    private func startObserving() {
        guard !isSetup else { return }

        let nc = NotificationCenter.default

        // Controller did connect observer.
        NotificationCenter.default.addObserver(self,
                       selector: #selector(controllerDidConnect),
                       name: .GCControllerDidConnect,
                       object: nil)

        // Controller did disconnect observer.
        nc.addObserver(self, selector:
                        #selector(controllerDidDisconnect),
                       name: .GCControllerDidDisconnect,
                       object: nil)
        isSetup = true
    }

    /// - Tag: ControllerDidConnect
    @objc private func controllerDidConnect(notification: Notification) {
        guard let controller = notification.object as? GCController else {
            fatalError("Invalid notification object.")
        }

        print("Connected \(controller.productCategory) game controller.")

        // Create a haptics engine for the controller.
        guard let engine = createEngine(for: controller, locality: .default) else { return }

        // Configure the event handlers for the controller buttons.
        delegate?.didConnect(controller: controller)

        self.engineMap[GCHapticsLocality.default] = engine
        self.controller = controller
    }

    /// - Tag: CreateEngine
    private func createEngine(for controller: GCController, locality: GCHapticsLocality) -> CHHapticEngine? {
        // Get the controller's haptics (if one exists), and create a
        // new CGHapticEngine for it, using the default locality.
        guard let engine = controller.haptics?.createEngine(withLocality: locality) else {
            print("Failed to create engine.")
            return nil
        }

        // The stopped handler alerts you of engine stoppage due to external causes.
        engine.stoppedHandler = { reason in
            print("The engine stopped because \(reason.message)")
        }

        // The reset handler provides an opportunity for your app to restart the engine in case of failure.
        engine.resetHandler = {
            // Try restarting the engine.
            print("The engine reset --> Restarting now!")
            do {
                try engine.start()
            } catch {
                print("Failed to restart the engine: \(error)")
            }
        }
        return engine
    }

    @objc private func controllerDidDisconnect(notification: Notification) {
        guard controller == notification.object as? GCController else { return }

        // dispose of engine and controller.
        engineMap.removeAll(keepingCapacity: true)
        controller = nil
        delegate?.didDisconnectController()
    }

    /// - Tag: PlayHapticsFile
    func playHapticsFile(named filename: String, locality: GCHapticsLocality = .default) {
        // Update the engine based on locality.
        guard let controller = controller else {
            print("Unable to play haptics: no game controller connected")
            return
        }

        var engine: CHHapticEngine!
        if let existingEngine = engineMap[locality] {
            engine = existingEngine
        } else if let newEngine = createEngine(for: controller, locality: locality) {
            engine = newEngine
        }

        guard engine != nil else {
            print("Unable to play haptics: no engine available for locality %@", locality)
            return
        }

        // Get the AHAP file URL.
        guard let url = Bundle.main.url(forResource: filename,
                                        withExtension: "ahap") else {
            print("Unable to find haptics file named '\(filename)'.")
            return
        }

        do {
            // Start the engine in case it's idle.
            try engine.start()

            // Tell the engine to play a pattern.
            try engine.playPattern(from: url)

        } catch { // Engine startup errors
            print("An error occured playing \(filename): \(error).")
        }
    }

}

extension CHHapticEngine.StoppedReason {
    var message: String {
        switch self {
        case .audioSessionInterrupt:
            return "the audio session was interrupted."
        case .applicationSuspended:
            return "the application was suspended."
        case .idleTimeout:
            return "an idle timeout occurred."
        case .systemError:
            return "a system error occurred."
        case .notifyWhenFinished:
            return "playback finished."
        case .engineDestroyed:
            return "the engine was destroyed."
        case .gameControllerDisconnect:
            return "the game controller disconnected."
        @unknown default:
            fatalError()
        }
    }
}


