import Vulkan

public class MaterialSystem {
  private let vulkanRenderer: VulkanRenderer
  private let setsPerMaterial: Int
  @Deferred var descriptorSetLayout: DescriptorSetLayout
  @Deferred private var descriptorPool: DescriptorPool
  public private(set) var materialRenderData: [ObjectIdentifier: MaterialRenderData] = [:]

  public init(vulkanRenderer: VulkanRenderer) throws {
    self.vulkanRenderer = vulkanRenderer
    self.setsPerMaterial = vulkanRenderer.swapchainImages.count 

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

    descriptorPool = try DescriptorPool.create(device: vulkanRenderer.device, createInfo: DescriptorPoolCreateInfo(
      flags: .none,
      maxSets: 10,
      poolSizes: [
        DescriptorPoolSize(
          type: .combinedImageSampler, descriptorCount: 10
        )
      ]
    ))
  }

  public func buildForMaterial(_ material: Material) {
    let descriptorSets = DescriptorSet.allocate(device: vulkanRenderer.device, allocateInfo: DescriptorSetAllocateInfo(
      descriptorPool: descriptorPool,
      descriptorSetCount: UInt32(setsPerMaterial),
      setLayouts: Array(repeating: descriptorSetLayout, count: setsPerMaterial)))
    
    for i in 0..<self.setsPerMaterial {
      let imageInfo = DescriptorImageInfo(
        sampler: vulkanRenderer.textureSampler, imageView: vulkanRenderer.textureImageView, imageLayout: .shaderReadOnlyOptimal 
      )

      let descriptorWrites = [
        WriteDescriptorSet(
          dstSet: descriptorSets[i],
          dstBinding: 0,
          dstArrayElement: 0,
          descriptorCount: 1,
          descriptorType: .combinedImageSampler,
          imageInfo: [imageInfo],
          bufferInfo: [],
          texelBufferView: [])
      ]

      vulkanRenderer.device.updateDescriptorSets(descriptorWrites: descriptorWrites, descriptorCopies: nil)
    }

    self.materialRenderData[ObjectIdentifier(material)] = MaterialRenderData(descriptorSets: descriptorSets)
  }
}

public class MaterialRenderData {
  public var descriptorSets: [DescriptorSet]

  public init(descriptorSets: [DescriptorSet]) {
    self.descriptorSets = descriptorSets
  }
}