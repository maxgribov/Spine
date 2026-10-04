import Foundation

/// Spec v6 cadence tolerance applies only to the mean of two raw callback rates.
enum LibraryBenchmarkPolicy {
    static let minimumCallbackFPS=30.0*(1.0-0.001)
    static func acceptsCallbackRounds(_ rates:[Double])->Bool {
        rates.count==2 && rates.allSatisfy {$0.isFinite && $0>0} && rates.reduce(0,+)/2>=minimumCallbackFPS
    }
    static func acceptsThermalSamples(_ states:[Int])->Bool {
        states.count==120 && states.allSatisfy {$0==ProcessInfo.ThermalState.nominal.rawValue}
    }
}
