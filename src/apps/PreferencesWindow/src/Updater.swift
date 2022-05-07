import Foundation

#if USE_SPARKLE
  import Sparkle
#endif

final class Updater: ObservableObject {
  public static let shared = Updater()

  public static let didFindValidUpdate = Notification.Name("didFindValidUpdate")
  public static let updaterDidNotFindUpdate = Notification.Name("updaterDidNotFindUpdate")

  #if USE_SPARKLE
    private let updaterController: SPUStandardUpdaterController
    private let delegate = SparkleDelegate()
  #endif

  @Published var canCheckForUpdates = false
  @Published var sessionInProgress = false

  private init() {
    #if USE_SPARKLE
      updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: delegate,
        userDriverDelegate: nil
      )

      updaterController.updater.publisher(for: \.canCheckForUpdates)
        .assign(to: &$canCheckForUpdates)
      updaterController.updater.publisher(for: \.sessionInProgress)
        .assign(to: &$sessionInProgress)
    #endif
  }

  func checkForUpdatesInBackground() {
    #if USE_SPARKLE
      delegate.includingBetaVersions = false
      updaterController.updater.checkForUpdatesInBackground()
    #endif
  }

  func checkForUpdatesStableOnly() {
    #if USE_SPARKLE
      delegate.includingBetaVersions = false
      updaterController.checkForUpdates(nil)
    #endif
  }

  func checkForUpdatesWithBetaVersion() {
    #if USE_SPARKLE
      delegate.includingBetaVersions = true
      updaterController.checkForUpdates(nil)
    #endif
  }

  private class SparkleDelegate: NSObject, SPUUpdaterDelegate,
    SPUStandardUserDriverDelegate
  {
    var includingBetaVersions = false

    func feedURLString(for updater: SPUUpdater) -> String? {
      var url = "https://appcast.pqrs.org/karabiner-elements-appcast.xml"
      if includingBetaVersions {
        url = "https://appcast.pqrs.org/karabiner-elements-appcast-devel.xml"
      }

      print("feedURLString \(url)")

      return url
    }

    func updater(_: SPUUpdater, didFindValidUpdate _: SUAppcastItem) {
      NotificationCenter.default.post(name: Updater.didFindValidUpdate, object: nil)
    }

    func updaterDidNotFindUpdate(_: SPUUpdater) {
      NotificationCenter.default.post(name: Updater.updaterDidNotFindUpdate, object: nil)
    }

    func updater(_: SPUUpdater, didAbortWithError error: Error) {
      print("Sparkle error: \(error)")
    }
  }
}
