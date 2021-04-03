import Foundation
import Vulkan

public class ManagedBuffer {
  @Deferred public var buffer: Buffer
  @Deferred public var bufferMemory: DeviceMemory
  var bufferSize = DeviceSize(0)
  var nextBufferDataIndex = 0
  var nextBufferIndex = 0
  @Deferred public var stagingBuffer: Buffer
  @Deferred public var stagingBufferMemory: DeviceMemory
  public var stagingBufferMemoryPointer: UnsafeMutableRawPointer?
  var stagingBufferSize = DeviceSize(0)

  private let usageFlags: BufferUsageFlags
  private let vulkanRenderer: VulkanRenderer

  public init(vulkanRenderer: VulkanRenderer, usageFlags: BufferUsageFlags) throws {
    self.vulkanRenderer = vulkanRenderer
    self.usageFlags = usageFlags
    try self.createBuffer(size: DeviceSize(50 * pow(10, 6)))
    try self.createStagingBuffer(size: DeviceSize(10 * pow(10, 6)))
  }

  private func createBuffer(size: DeviceSize) throws {
    $buffer.value?.destroy()
    $bufferMemory.value?.free()
    $bufferMemory.value?.destroy()
    (buffer, bufferMemory) = try vulkanRenderer.createBuffer(
      size: size,
      usage: [usageFlags, .transferDst],
      properties: [.hostVisible, .hostCoherent])
    bufferSize = size
  }

  private func createStagingBuffer(size: DeviceSize) throws {
    $stagingBuffer.value?.destroy()
    $stagingBufferMemory.value?.unmapMemory()
    $stagingBufferMemory.value?.free()
    $stagingBufferMemory.value?.destroy()
    (stagingBuffer, stagingBufferMemory) = try vulkanRenderer.createBuffer(
      size: size,
      usage: .transferSrc,
      properties: [.hostVisible, .hostCoherent])
    try stagingBufferMemory.mapMemory(offset: 0, size: size, flags: [], data: &stagingBufferMemoryPointer)
    stagingBufferSize = size
  }

  public func addChunk<T>(_ data: [T], rawCount: Int? = nil) throws -> Int {
    let dataSize = MemoryLayout<T>.size * data.count
    if nextBufferDataIndex + dataSize > bufferSize {
      print("recreating buffer because ran out of memory")
      try createBuffer(size: max(DeviceSize(Double(bufferSize) * 1.2), DeviceSize(nextBufferDataIndex + dataSize)))
    }
    if dataSize > stagingBufferSize {
      print("recreating staging buffer because ran out of memory")
      try createStagingBuffer(size: max(DeviceSize(Double(stagingBufferSize) * 1.2), DeviceSize(dataSize)))
    }
  
    stagingBufferMemoryPointer?.copyMemory(from: data, byteCount: dataSize)
    try vulkanRenderer.copyBuffer(
      srcBuffer: stagingBuffer,
      dstBuffer: buffer,
      size: DeviceSize(dataSize),
      srcOffset: 0,
      dstOffset: DeviceSize(nextBufferDataIndex))

    defer { 
      nextBufferDataIndex += dataSize
      /*if let alignment = alignment {
        nextBufferDataIndex = Int(ceil(Double(nextBufferDataIndex) / Double(alignment)) * Double(alignment))
      }*/
      if let rawCount = rawCount {
        nextBufferIndex += rawCount
      } else {
        nextBufferIndex += data.count
      }
    }
    return nextBufferIndex
  }
}