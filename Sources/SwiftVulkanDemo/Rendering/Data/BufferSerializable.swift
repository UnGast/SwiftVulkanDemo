/// can be put into a Vulkan buffer
public protocol BufferSerializable {
  associatedtype SerializedElement

  var serializedData: [SerializedElement] { get }
}

extension Array where Element: BufferSerializable {
  var serializedData: [Element.SerializedElement] {
    flatMap { $0.serializedData }
  }
}