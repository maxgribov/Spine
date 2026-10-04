import Foundation
precondition(!LibraryBenchmarkPolicy.acceptsCallbackRounds([29.969,29.969]))
precondition(LibraryBenchmarkPolicy.acceptsCallbackRounds([29.97,29.97]))
precondition(LibraryBenchmarkPolicy.acceptsCallbackRounds([29.999969062078055,29.993633850751312]))
precondition(!LibraryBenchmarkPolicy.acceptsCallbackRounds([30]))
precondition(!LibraryBenchmarkPolicy.acceptsCallbackRounds([.nan,30]))
precondition(!LibraryBenchmarkPolicy.acceptsCallbackRounds([.infinity,30]))
print("PASS: raw callback boundary, two-round requirement and nonfinite rejection")

let nominal=Array(repeating:ProcessInfo.ThermalState.nominal.rawValue,count:120)
precondition(LibraryBenchmarkPolicy.acceptsThermalSamples(nominal))
for state in [ProcessInfo.ThermalState.fair,.serious,.critical] {
    var samples=nominal;samples[37]=state.rawValue
    precondition(!LibraryBenchmarkPolicy.acceptsThermalSamples(samples))
    precondition(samples.count==120 && samples[37]==state.rawValue)
}
precondition(!LibraryBenchmarkPolicy.acceptsThermalSamples([]))
precondition(!LibraryBenchmarkPolicy.acceptsThermalSamples(Array(nominal.dropLast())))
print("PASS: nominal thermal samples accepted; any fair/serious/critical or incomplete samples rejected unchanged")
