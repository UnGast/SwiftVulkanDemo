import Foundation

public func measureDuration<T>(_ id: String, block: () throws -> T) rethrows -> T {
  let start = Date.timeIntervalSinceReferenceDate
  let result = try block()
  let duration = Date.timeIntervalSinceReferenceDate - start
  print(id, "took", duration, "seconds")
  return result
}