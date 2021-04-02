import GfxMath
import Vulkan
import struct Swim.Image
import enum Swim.RGBA

public class MaterialSystem {
  private let vulkanRenderer: VulkanRenderer
  private let setsPerMaterial: Int
  @Deferred var descriptorSetLayout: DescriptorSetLayout
  @Deferred private var descriptorPool: DescriptorPool
  @Deferred private var textureSampler: Sampler 
  public private(set) var materialRenderData: [ObjectIdentifier: MaterialRenderData] = [:]

  private var unusedDescriptorSets = [DescriptorSet]()
  private var unusedTextureInfos = [TextureInfo]()
  var currentFrameCompleteDestructorQueue: [() -> ()] = []

  public init(vulkanRenderer: VulkanRenderer) throws {
    self.vulkanRenderer = vulkanRenderer
    self.setsPerMaterial = vulkanRenderer.swapchainImages.count 

    try createDescriptorSetLayout()
    try createDescriptorPool()
    try createTextureSampler()
  }

  func createDescriptorSetLayout() throws {
    let samplerLayoutBinding = DescriptorSetLayoutBinding(
      binding: 0,
      descriptorType: .combinedImageSampler,
      descriptorCount: 1,
      stageFlags: .fragment,
      immutableSamplers: nil
    )

    descriptorSetLayout = try DescriptorSetLayout.create(device: vulkanRenderer.device, createInfo: DescriptorSetLayoutCreateInfo(
      flags: .none, bindings: [samplerLayoutBinding]
    ))
  }

  func createDescriptorPool() throws {
    descriptorPool = try DescriptorPool.create(device: vulkanRenderer.device, createInfo: DescriptorPoolCreateInfo(
      flags: [],
      maxSets: 10,
      poolSizes: [
        DescriptorPoolSize(
          type: .combinedImageSampler, descriptorCount: 30
        )
      ]
    ))
  }

  func createTextureSampler() throws {
    textureSampler = try Sampler(device: vulkanRenderer.device, createInfo: SamplerCreateInfo(
      magFilter: .linear,
      minFilter: .linear,
      mipmapMode: .linear,
      addressModeU: .repeat,
      addressModeV: .repeat,
      addressModeW: .repeat,
      mipLodBias: 0,
      anisotropyEnable: true,
      maxAnisotropy: vulkanRenderer.physicalDevice.properties.limits.maxSamplerAnisotropy,
      compareEnable: false,
      compareOp: .always,
      minLod: 0,
      maxLod: 0,
      borderColor: .intOpaqueBlack,
      unnormalizedCoordinates: false
    ))
  }

  func createTextureImage(imageData: Swim.Image<RGBA, UInt8>) throws -> (Vulkan.Image, Vulkan.DeviceMemory) {
    let imageWidth = Int32(imageData.width)
    let imageHeight = Int32(imageData.height)

    let (textureImage, textureImageMemory) = try vulkanRenderer.createImage(
      width: UInt32(imageWidth),
      height: UInt32(imageHeight),
      format: .R8G8B8A8_SRGB /* note */,
      tiling: .optimal,
      usage: [.transferDst, .sampled],
      properties: [.hostVisible, .hostCoherent])

    try transferImageDataToImage(imageData: imageData, image: textureImage)
  
    return (textureImage, textureImageMemory)
  }

  func transferImageDataToImage(imageData: Swim.Image<RGBA, UInt8>, image: Vulkan.Image) throws {
    let imageWidth = Int32(imageData.width)
    let imageHeight = Int32(imageData.height)
    let dataSize = imageData.pixelCount * 4

    let (stagingBuffer, stagingBufferMemory) = try vulkanRenderer.createBuffer(
      size: DeviceSize(dataSize), usage: [.transferSrc], properties: [.hostVisible, .hostCoherent])
    
    var dataPointer: UnsafeMutableRawPointer? = nil
    try stagingBufferMemory.mapMemory(offset: 0, size: DeviceSize(dataSize), flags: .none, data: &dataPointer)
    dataPointer?.copyMemory(from: imageData.getData(), byteCount: dataSize)
    stagingBufferMemory.unmapMemory()

    try vulkanRenderer.transitionImageLayout(image: image, format: .R8G8B8A8_SRGB /* note */, oldLayout: .undefined, newLayout: .transferDstOptimal)

    try vulkanRenderer.copyBufferToImage(buffer: stagingBuffer, image: image, width: UInt32(imageWidth), height: UInt32(imageHeight))

    try vulkanRenderer.transitionImageLayout(image: image, format: .R8G8B8A8_SRGB /* note */, oldLayout: .transferDstOptimal, newLayout: .shaderReadOnlyOptimal)

    stagingBuffer.destroy()
    stagingBufferMemory.free()
  }

  func createTextureImageView(image: Vulkan.Image) throws -> ImageView {
    return try vulkanRenderer.createImageView(image: image, format: .R8G8B8A8_SRGB /* note */, aspectFlags: .color)
  }

  public func buildForMaterial(_ material: Material) throws {
    var descriptorSets: [DescriptorSet] = []

    let reusedDescriptorSetsCount = min(setsPerMaterial, unusedDescriptorSets.count)
    descriptorSets = Array(unusedDescriptorSets[0..<reusedDescriptorSetsCount])
    unusedDescriptorSets.removeFirst(reusedDescriptorSetsCount)
    
    let missingDescriptorSetsCount = setsPerMaterial - reusedDescriptorSetsCount

    if missingDescriptorSetsCount > 0 {
      let newAllocatedDescriptorSets = DescriptorSet.allocate(device: vulkanRenderer.device, allocateInfo: DescriptorSetAllocateInfo(
        descriptorPool: descriptorPool,
        descriptorSetCount: UInt32(missingDescriptorSetsCount),
        setLayouts: Array(repeating: descriptorSetLayout, count: setsPerMaterial)))
      descriptorSets.append(contentsOf: newAllocatedDescriptorSets)
    }

    let textureInfo: TextureInfo
    if let unusedTextureInfo = unusedTextureInfos.last, unusedTextureInfo.size == ISize2(material.texture.width, material.texture.height) {
      _ = unusedTextureInfos.popLast()
      textureInfo = unusedTextureInfo
      try transferImageDataToImage(imageData: material.texture, image: textureInfo.textureImage)
    } else {
      let (textureImage, textureImageMemory) = try measureDuration("textureImage and textureImageMemory") {
        try createTextureImage(imageData: material.texture)
      }
      let textureImageView = try measureDuration("textureImageView") {
        try createTextureImageView(image: textureImage)
      }
      textureInfo = TextureInfo(size: ISize2(material.texture.width, material.texture.height),
        textureImage: textureImage, textureImageMemory: textureImageMemory, textureImageView: textureImageView)
    }

    measureDuration("descriptorWrites") {
      var descriptorWrites = [WriteDescriptorSet]()    
      for i in 0..<self.setsPerMaterial {
        let imageInfo = DescriptorImageInfo(
          sampler: textureSampler, imageView: textureInfo.textureImageView, imageLayout: .shaderReadOnlyOptimal 
        )

        descriptorWrites.append(
          WriteDescriptorSet(
            dstSet: descriptorSets[i],
            dstBinding: 0,
            dstArrayElement: 0,
            descriptorCount: 1,
            descriptorType: .combinedImageSampler,
            imageInfo: [imageInfo],
            bufferInfo: [],
            texelBufferView: []))
      }
      vulkanRenderer.device.updateDescriptorSets(descriptorWrites: descriptorWrites, descriptorCopies: nil)
    }

    self.materialRenderData[ObjectIdentifier(material)] = MaterialRenderData(
      descriptorSets: descriptorSets,
      textureInfo: TextureInfo(
        size: ISize2(material.texture.width, material.texture.height),
        textureImage: textureInfo.textureImage,
        textureImageMemory: textureInfo.textureImageMemory,
        textureImageView: textureInfo.textureImageView))
  }

  public func removeMaterial(material: Material) throws {
    if let renderData = materialRenderData[ObjectIdentifier(material)] {
      currentFrameCompleteDestructorQueue.append { [unowned self, renderData] in
        unusedDescriptorSets.append(contentsOf: renderData.descriptorSets)
        unusedTextureInfos.append(renderData.textureInfo)
        materialRenderData[ObjectIdentifier(material)] = nil
      }
    }
  }
}

public class MaterialRenderData {
  public var descriptorSets: [DescriptorSet]
  public var textureInfo: TextureInfo

  public init(descriptorSets: [DescriptorSet], textureInfo: TextureInfo) {
    self.descriptorSets = descriptorSets
    self.textureInfo = textureInfo
  }
}

public class TextureInfo {
  public var size: ISize2
  public var textureImage: Vulkan.Image
  public var textureImageMemory: DeviceMemory
  public var textureImageView: ImageView

  public init(size: ISize2, textureImage: Vulkan.Image, textureImageMemory: DeviceMemory, textureImageView: ImageView) {
    self.size = size
    self.textureImage = textureImage
    self.textureImageMemory = textureImageMemory
    self.textureImageView = textureImageView
  }
}