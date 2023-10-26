import Combine
import SwiftUI

public class StickManager: ObservableObject {
  public static let shared = StickManager()

  class StickSensor: ObservableObject {
    @Published var lastDoubleValue = 0.0

    @MainActor
    func add(
      _ logicalMax: Int64,
      _ logicalMin: Int64,
      _ integerValue: Int64
    ) {
      if logicalMax != logicalMin {
        // -1.0 ... 1.0
        lastDoubleValue =
          (Double(integerValue - logicalMin) / Double(logicalMax - logicalMin) - 0.5) * 2.0
      }
    }
  }

  class Stick: ObservableObject {
    @Published var horizontal = StickSensor()
    @Published var vertical = StickSensor()
    @Published var radian = 0.0
    @Published var magnitude = 0.0
    @Published var strokeAcceleration = 0.0
    @Published var deadzoneRadian = 0.0
    @Published var deadzoneMagnitude = 0.0
    @Published var accelerationFixed = false
    @Published var radianDiff = 0.0
    @Published var deltaHorizontal = 0.0
    @Published var deltaVertical = 0.0
    @Published var deltaRadian = 0.0
    @Published var deltaMagnitude = 0.0
    let remainDeadzoneThresholdMilliseconds: UInt64 = 100
    let strokeAccelerationMeasurementTime = 0.05  // 50 ms
    var previousHorizontalDoubleValue = 0.0
    var previousVerticalDoubleValue = 0.0

    var deadzoneTask: Task<(), Never>?
    var updateTimer: Cancellable?

    @MainActor
    func setUpdateTimer() {
      if updateTimer == nil {
        updateTimer = Timer.publish(every: 0.02, on: .main, in: .default).autoconnect().sink { _ in
          self.update()
        }
      }
    }

    @MainActor
    private func update() {
      deltaHorizontal = horizontal.lastDoubleValue - previousHorizontalDoubleValue
      deltaVertical = vertical.lastDoubleValue - previousVerticalDoubleValue
      deltaRadian = atan2(deltaVertical, deltaHorizontal)
      deltaMagnitude = min(1.0, sqrt(pow(deltaHorizontal, 2) + pow(deltaVertical, 2)))

      radian = atan2(vertical.lastDoubleValue, horizontal.lastDoubleValue)
      magnitude = min(
        1.0,
        sqrt(pow(vertical.lastDoubleValue, 2) + pow(horizontal.lastDoubleValue, 2)))

      let deadzone = 0.1
      if abs(vertical.lastDoubleValue) < deadzone && abs(horizontal.lastDoubleValue) < deadzone {
        if deadzoneTask == nil {
          deadzoneTask = Task { @MainActor in
            do {
              try await Task.sleep(nanoseconds: remainDeadzoneThresholdMilliseconds * NSEC_PER_MSEC)

              strokeAcceleration = 0.0
              accelerationFixed = false

              updateTimer?.cancel()
              updateTimer = nil
            } catch {
              print("cancelled")
            }
          }
        }
      } else {
        if deadzoneTask != nil {
          deadzoneRadian = deltaRadian
          deadzoneMagnitude = magnitude

          deadzoneTask?.cancel()
          deadzoneTask = nil
        }
      }

      radianDiff = abs(radian - deadzoneRadian).truncatingRemainder(dividingBy: 2 * Double.pi)
      if radianDiff > Double.pi {
        radianDiff = 2 * Double.pi - radianDiff
      }

      if !accelerationFixed {
        if radianDiff < 0.174533 {
          let acceleration = max(0.0, magnitude - deadzoneMagnitude)
          strokeAcceleration = acceleration
        } else {
          accelerationFixed = true
        }
      }

      previousHorizontalDoubleValue = horizontal.lastDoubleValue
      previousVerticalDoubleValue = vertical.lastDoubleValue
    }
  }

  @Published var rightStick = Stick()
}
