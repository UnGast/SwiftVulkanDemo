extension UInt32: BufferSerializable {
  public var serializedData: [UInt32] {
    [self]
  }
}