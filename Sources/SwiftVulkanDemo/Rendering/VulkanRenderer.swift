import Foundation
import CSDL2
import CSDL2Vulkan
import CVulkan
import Vulkan
import CTinyObjLoader
import GfxMath
import ApplicationBackendSDL2Vulkan
import class SwiftGUI.CpuBufferDrawingSurface
import FirebladeECS
// SPRIV Compiler? https://github.com/stuartcarnie/SwiftSPIRV-Cross

public class VulkanRenderer {
  @Deferred var window: SDL2VulkanWindow
  @Deferred var instance: Instance
  @Deferred var surface: SurfaceKHR
  @Deferred var physicalDevice: PhysicalDevice
  @Deferred var queueFamilyIndex: UInt32
  @Deferred var device: Device
  @Deferred var queue: Queue
  @Deferred var swapchain: Swapchain
  @Deferred var swapchainImageFormat: Format
  @Deferred var swapchainExtent: Extent2D
  @Deferred var swapchainImages: [Image]
  @Deferred var imageViews: [ImageView]
  @Deferred var renderPass: RenderPass
  @Deferred var graphicsPipeline: Pipeline
  @Deferred var descriptorSetLayout: DescriptorSetLayout
  @Deferred var pipelineLayout: PipelineLayout
  @Deferred var framebuffers: [Framebuffer]
  @Deferred var commandPool: CommandPool
  @Deferred var depthImage: Image
  @Deferred var depthImageMemory: DeviceMemory
  @Deferred var depthImageView: ImageView
  @Deferred var textureImage: Image
  @Deferred var textureImageMemory: DeviceMemory
  @Deferred var textureImageView: ImageView
  @Deferred var textureSampler: Sampler
  @Deferred var gui: GUI
  @Deferred var guiSurface: SwiftGUI.CpuBufferDrawingSurface
  var currentVertexBufferSize: DeviceSize = 0
  @Deferred var vertexBuffer: Buffer
  @Deferred var vertexBufferMemory: DeviceMemory
  var currentIndexBufferSize: DeviceSize = 0
  @Deferred var indexBuffer: Buffer
  @Deferred var indexBufferMemory: DeviceMemory
  @Deferred var uniformBuffers: [Buffer]
  @Deferred var uniformBuffersMemory: [DeviceMemory]
  @Deferred var mainMaterial: Material
  @Deferred var materialSystem: MaterialSystem
  @Deferred var descriptorPool: DescriptorPool
  @Deferred var descriptorSets: [DescriptorSet]
  @Deferred var commandBuffers: [CommandBuffer]
  @Deferred var imageAvailableSemaphores: [Semaphore]
  @Deferred var renderFinishedSemaphores: [Semaphore]
  @Deferred var inFlightFences: [Fence]

  //let planeMesh = PlaneMesh()
  //let cubeMesh = CubeMesh()
  //let objMesh = ObjMesh(fileUrl: Bundle.module.url(forResource: "viking_room", withExtension: "obj")!)

  var camera = Camera(position: FVec3([0.01, 0.01, 0.01]))

  var vertices: [Vertex] = []/*[
    Vertex(position: Position3(x: -0.5, y: 0.5, z: 0.5), color: Color(r: 1, g: 0, b: 0), texCoord: Position2(x: 1, y: 0)),
    Vertex(position: Position3(x: 0.5, y: 0.5, z: 0.5), color: Color(r: 1, g: 0, b: 0), texCoord: Position2(x: 0, y: 0)),
    Vertex(position: Position3(x: 0.5, y: -0.5, z: 0.5), color: Color(r: 1, g: 0, b: 0), texCoord: Position2(x: 0, y: 1)),
    Vertex(position: Position3(x: -0.5, y: -0.5, z: 0.5), color: Color(r: 1, g: 0, b: 0), texCoord: Position2(x: 1, y: 1)),

    Vertex(position: Position3(x: -0.2, y: 0.8, z: 0.4), color: Color(r: 0, g: 0, b: 1), texCoord: Position2(x: 1, y: 0)),
    Vertex(position: Position3(x: 0.8, y: 0.8, z: 0.4), color: Color(r: 0, g: 0, b: 1), texCoord: Position2(x: 0, y: 0)),
    Vertex(position: Position3(x: 0.8, y: -0.2, z: 0.4), color: Color(r: 0, g: 0, b: 1), texCoord: Position2(x: 0, y: 1)),
    Vertex(position: Position3(x: -0.2, y: -0.2, z: 0.4), color: Color(r: 0, g: 0, b: 1), texCoord: Position2(x: 1, y: 1)),
  ]*/

  var indices: [UInt32] = []/*[
    4, 5, 6, 4, 6, 7,
    0, 1, 2, 0, 2, 3,
  ]*/

  let maxFramesInFlight = 2
  var currentFrameIndex = 0
  var imagesInFlightWithFences: [UInt32: Fence] = [:]

  public init(window: SDL2VulkanWindow) throws {
    self.window = window

    try self.createInstance()

    try self.createSurface()

    try self.pickPhysicalDevice()

    try self.getQueueFamilyIndex()

    try self.createDevice()

    self.queue = Queue.create(fromDevice: self.device, presentFamilyIndex: queueFamilyIndex)

    try self.createSwapchain()

    try self.createImageViews()

    try self.createRenderPass()

    self.materialSystem = try MaterialSystem(vulkanRenderer: self)

    try self.createDescriptorSetLayout()

    try self.createGraphicsPipeline()

    try self.createCommandPool()

    try self.createDepthResources()

    try self.createFramebuffers()

    try self.createGUI()

    try self.createGUISurface()

    try self.createTextureImage()

    try self.createTextureImageView()

    try self.createTextureSampler()

    try self.createVertexBuffer(size: 48 * 1)

    try self.createIndexBuffer(size: 4 * 1)

    try self.createUniformBuffers()

    self.mainMaterial = try Material.load(textureUrl: Bundle.module.url(forResource: "viking_room", withExtension: "png")!)
    try self.materialSystem.buildForMaterial(self.mainMaterial)

    try self.createDescriptorPool()

    try self.createDescriptorSets()

    try self.createCommandBuffers()

    try self.createSyncObjects()
  }

  func createInstance() throws {
    let sdlExtensions = try! window.getVulkanInstanceExtensions()

    let createInfo = InstanceCreateInfo(
      applicationInfo: nil,
      enabledLayerNames: ["VK_LAYER_KHRONOS_validation"],
      enabledExtensionNames: sdlExtensions
    )

    self.instance = try Instance.createInstance(createInfo: createInfo)
  }

  func createSurface() throws {
    let drawingSurface = window.getVulkanDrawingSurface(instance: instance)
    self.surface = drawingSurface.vulkanSurface
  }

  func pickPhysicalDevice() throws {
    let devices = try instance.enumeratePhysicalDevices()
    self.physicalDevice = devices[0]
  }

  func getQueueFamilyIndex() throws {
    var queueFamilyIndex: UInt32?
    for properties in physicalDevice.queueFamilyProperties {
      if try! physicalDevice.hasSurfaceSupport(
        for: properties,
        surface:
          surface /*(properties.queueCount & QueueFamilyProperties.Flags.graphicsBit.rawValue == QueueFamilyProperties.Flags.graphicsBit.rawValue) &&*/
      ) {
        queueFamilyIndex = properties.index
      }
    }

    guard let queueFamilyIndexUnwrapped = queueFamilyIndex else {
      throw VulkanApplicationError.noSuitableQueueFamily
    }

    self.queueFamilyIndex = queueFamilyIndexUnwrapped
  }

  func createDevice() throws {
    let queueCreateInfo = DeviceQueueCreateInfo(
      flags: .none, queueFamilyIndex: queueFamilyIndex, queuePriorities: [1.0])

    var physicalDeviceFeatures = PhysicalDeviceFeatures()
    physicalDeviceFeatures.samplerAnisotropy = true

    self.device = try physicalDevice.createDevice(
      createInfo: DeviceCreateInfo(
        flags: .none,
        queueCreateInfos: [queueCreateInfo],
        enabledLayers: [],
        enabledExtensions: ["VK_KHR_swapchain"],
        enabledFeatures: physicalDeviceFeatures))
  }

  func createSwapchain() throws {
    let capabilities = try physicalDevice.getSurfaceCapabilities(surface: surface)
    let surfaceFormat = try selectFormat(for: physicalDevice, surface: surface)

    // Find a supported composite alpha mode - one of these is guaranteed to be set
    var compositeAlpha: CompositeAlphaFlags = .opaque
    let desiredCompositeAlpha =
      [compositeAlpha, .preMultiplied, .postMultiplied, .inherit]

    for desired in desiredCompositeAlpha {
      if capabilities.supportedCompositeAlpha.contains(desired) {
        compositeAlpha = desired
        break
      }
    }

    self.swapchain = try Swapchain.create(
      inDevice: device,
      createInfo: SwapchainCreateInfo(
        flags: .none,
        surface: surface,
        minImageCount: capabilities.minImageCount + 1,
        imageFormat: surfaceFormat.format,
        imageColorSpace: surfaceFormat.colorSpace,
        imageExtent: capabilities.maxImageExtent,
        imageArrayLayers: 1,
        imageUsage: .colorAttachment,
        imageSharingMode: .exclusive,
        queueFamilyIndices: [],
        preTransform: capabilities.currentTransform,
        compositeAlpha: compositeAlpha,
        presentMode: .fifo,
        clipped: true,
        oldSwapchain: nil
      ))
      self.swapchainImageFormat = surfaceFormat.format
      self.swapchainExtent = capabilities.minImageExtent

    self.swapchainImages = try self.swapchain.getSwapchainImages()
  }

  func selectFormat(for gpu: PhysicalDevice, surface: SurfaceKHR) throws -> SurfaceFormat {
    let formats = try gpu.getSurfaceFormats(for: surface)

    for format in formats {
      if format.format == .B8G8R8A8_SRGB {
        return format
      }
    }

    return formats[0]
  }

  func createImageView(image: Image, format: Format, aspectFlags: ImageAspectFlags) throws -> ImageView {
    try ImageView.create(device: device, createInfo: ImageViewCreateInfo(
      flags: .none,
      image: image,
      viewType: .type2D,
      format: format,
      components: ComponentMapping.identity,
      subresourceRange: ImageSubresourceRange(
        aspectMask: aspectFlags,
        baseMipLevel: 0,
        levelCount: 1,
        baseArrayLayer: 0,
        layerCount: 1
      )
    ))
  }

  func createImageViews() throws {
    self.imageViews = try swapchainImages.map {
      try createImageView(image: $0, format: swapchainImageFormat, aspectFlags: .color)
    }
  }

  func createRenderPass() throws {
    let colorAttachment = AttachmentDescription(
      flags: .none,
      format: swapchainImageFormat,
      samples: ._1bit,
      loadOp: .clear,
      storeOp: .store,
      stencilLoadOp: .dontCare,
      stencilStoreOp: .dontCare,
      initialLayout: .undefined,
      finalLayout: .presentSrc 
    )

    let colorAttachmentRef = AttachmentReference(
      attachment: 0, layout: .colorAttachmentOptimal 
    )

    let depthAttachment = AttachmentDescription(
      flags: .none,
      // maybe should choose this with function as well (like for createDepthImage)
      format: .D32_SFLOAT, 
      samples: ._1bit,
      loadOp: .clear,
      storeOp: .dontCare,
      stencilLoadOp: .dontCare,
      stencilStoreOp: .dontCare,
      initialLayout: .undefined,
      finalLayout: .depthStencilAttachmentOptimal
    )

    let depthAttachmentRef = AttachmentReference(
      attachment: 1,
      layout: .depthStencilAttachmentOptimal
    )

    let subpass = SubpassDescription(
      flags: .none,
      pipelineBindPoint: .graphics,
      inputAttachments: nil,
      colorAttachments: [colorAttachmentRef],
      resolveAttachments: nil,
      depthStencilAttachment: depthAttachmentRef,
      preserveAttachments: nil
    )

    let dependency = SubpassDependency(
      srcSubpass: VK_SUBPASS_EXTERNAL,
      dstSubpass: 0,
      srcStageMask: [.colorAttachmentOutput, .earlyFragmentTests],
      dstStageMask: [.colorAttachmentOutput, .earlyFragmentTests],
      srcAccessMask: [],
      dstAccessMask: [.colorAttachmentWrite, .depthStencilAttachmentWrite],
      dependencyFlags: .none
    )

    let renderPassInfo = RenderPassCreateInfo(
      flags: .none,
      attachments: [colorAttachment, depthAttachment],
      subpasses: [subpass],
      dependencies: [dependency]
    )

    self.renderPass = try RenderPass.create(createInfo: renderPassInfo, device: device)
  }

  func createDescriptorSetLayout() throws {
    let uboLayoutBinding = DescriptorSetLayoutBinding(
      binding: 0,
      descriptorType: .uniformBuffer,
      descriptorCount: 1,
      stageFlags: .vertex,
      immutableSamplers: nil
    )

    /*let samplerLayoutBinding = DescriptorSetLayoutBinding(
      binding: 1,
      descriptorType: .combinedImageSampler,
      descriptorCount: 1,
      stageFlags: .fragment,
      immutableSamplers: nil
    )*/

    descriptorSetLayout = try DescriptorSetLayout.create(device: device, createInfo: DescriptorSetLayoutCreateInfo(
      flags: .none, bindings: [uboLayoutBinding, /*samplerLayoutBinding*/]
    ))
  }

  func createGraphicsPipeline() throws {
    let vertexShaderCode: Data = try Data(contentsOf: Bundle.module.url(forResource: "vertex", withExtension: "spv")!)
    let fragmentShaderCode: Data = try Data(contentsOf: Bundle.module.url(forResource: "fragment", withExtension: "spv")!)

    let vertexShaderModule = try ShaderModule(device: device, createInfo: ShaderModuleCreateInfo(
      code: vertexShaderCode
    ))
    let vertexShaderStageCreateInfo = PipelineShaderStageCreateInfo(
      flags: .none,
      stage: .vertex,
      module: vertexShaderModule,
      pName: "main",
      specializationInfo: nil)

    let fragmentShaderModule = try ShaderModule(device: device, createInfo: ShaderModuleCreateInfo(
      code: fragmentShaderCode
    ))
    let fragmentShaderStageCreateInfo = PipelineShaderStageCreateInfo(
      flags: .none,
      stage: .fragment,
      module: fragmentShaderModule,
      pName: "main",
      specializationInfo: nil)

    let shaderStages = [vertexShaderStageCreateInfo, fragmentShaderStageCreateInfo]

    let vertexInputBindingDescription = Vertex.inputBindingDescription
    let vertexInputAttributeDescriptions = Vertex.inputAttributeDescriptions

    let vertexInputInfo = PipelineVertexInputStateCreateInfo(
      vertexBindingDescriptions: [vertexInputBindingDescription],
      vertexAttributeDescriptions: vertexInputAttributeDescriptions
    )

    let inputAssembly = PipelineInputAssemblyStateCreateInfo(topology: .triangleList, primitiveRestartEnable: false)

    let viewport = Viewport(x: 0, y: 0, width: Float(swapchainExtent.width), height: Float(swapchainExtent.height), minDepth: 0, maxDepth: 1)

    let scissor = Rect2D(offset: Offset2D(x: 0, y: 0), extent: swapchainExtent)

    let viewportState = PipelineViewportStateCreateInfo(
      viewports: [viewport],
      scissors: [scissor]
    )

    let rasterizer = PipelineRasterizationStateCreateInfo(
      depthClampEnable: false,
      rasterizerDiscardEnable: false,
      polygonMode: .fill,
      cullMode: .none,
      frontFace: .clockwise,
      depthBiasEnable: false,
      depthBiasConstantFactor: 0,
      depthBiasClamp: 0,
      depthBiasSlopeFactor: 0,
      lineWidth: 1
    )

    let multisampling = PipelineMultisampleStateCreateInfo(
      rasterizationSamples: ._1,
      sampleShadingEnable: false,
      minSampleShading: 1,
      sampleMask: nil, 
      alphaToCoverageEnable: false,
      alphaToOneEnable: false
    )

    let colorBlendAttachment = PipelineColorBlendAttachmentState(
      blendEnable: false,
      srcColorBlendFactor: .one,
      dstColorBlendFactor: .zero,
      colorBlendOp: .add,
      srcAlphaBlendFactor: .one,
      dstAlphaBlendFactor: .zero,
      alphaBlendOp: .add,
      colorWriteMask: [.r, .g, .b, .a]
    )

    let colorBlending = PipelineColorBlendStateCreateInfo(
      logicOpEnable: false,
      logicOp: .copy,
      attachments: [colorBlendAttachment],
      blendConstants: (0, 0, 0, 0)
    )

    let dynamicStates = [DynamicState.viewport, DynamicState.lineWidth]

    let dynamicState = PipelineDynamicStateCreateInfo(
      dynamicStates: dynamicStates
    )

    let pipelineLayoutInfo = PipelineLayoutCreateInfo(
      flags: .none,
      setLayouts: [descriptorSetLayout, materialSystem.descriptorSetLayout],
      pushConstantRanges: [])

    let pipelineLayout = try PipelineLayout.create(device: device, createInfo: pipelineLayoutInfo)

    let pipelineInfo = GraphicsPipelineCreateInfo(
      flags: [],
      stages: shaderStages,
      vertexInputState: vertexInputInfo,
      inputAssemblyState: inputAssembly,
      tessellationState: nil,
      viewportState: viewportState,
      rasterizationState: rasterizer,
      multisampleState: multisampling,
      depthStencilState: PipelineDepthStencilStateCreateInfo(
        depthTestEnable: true,
        depthWriteEnable: true,
        depthCompareOp: .less,
        depthBoundsTestEnable: false,
        stencilTestEnable: false,
        front: .dontCare,
        back: .dontCare, 
        minDepthBounds: 0,
        maxDepthBounds: 1
      ),
      colorBlendState: colorBlending,
      dynamicState: nil,
      layout: pipelineLayout,
      renderPass: renderPass,
      subpass: 0,
      basePipelineHandle: nil,
      basePipelineIndex: 0 
    )

    let graphicsPipeline = try Pipeline(device: device, createInfo: pipelineInfo)

    self.graphicsPipeline = graphicsPipeline
    self.pipelineLayout = pipelineLayout
  }

  func createFramebuffers() throws {
    self.framebuffers = try imageViews.map { imageView in
      let framebufferInfo = FramebufferCreateInfo(
        flags: [],
        renderPass: renderPass,
        attachments: [imageView, depthImageView],
        width: swapchainExtent.width,
        height: swapchainExtent.height,
        layers: 1 
      )
      return try Framebuffer(device: device, createInfo: framebufferInfo)
    }
  }

  func createCommandPool() throws {
    self.commandPool = try CommandPool.create(from: device, info: CommandPoolCreateInfo(
      flags: .none,
      queueFamilyIndex: queueFamilyIndex
    ))
  }

  func createBuffer(size: DeviceSize, usage: BufferUsageFlags, properties: MemoryPropertyFlags) throws -> (Buffer, DeviceMemory) {
    let bufferInfo = BufferCreateInfo(
      flags: .none,
      size: size,
      usage: usage,
      sharingMode: .exclusive,
      queueFamilyIndices: nil)
    let buffer = try Buffer.create(device: device, createInfo: bufferInfo)

    let memRequirements = buffer.memoryRequirements

    let bufferMemory = try DeviceMemory.allocateMemory(inDevice: device, allocInfo: MemoryAllocateInfo(
      allocationSize: memRequirements.size,
      memoryTypeIndex: try findMemoryType(typeFilter: memRequirements.memoryTypeBits, properties: properties.rawValue)
    ))

    try buffer.bindMemory(memory: bufferMemory)

    return (buffer, bufferMemory)
  }

  func findMemoryType(typeFilter: UInt32, properties: UInt32) throws -> UInt32 {
    let memProperties = try physicalDevice.getMemoryProperties()
    for (index, checkType) in memProperties.memoryTypes.enumerated() {
      if typeFilter & (1 << index) != 0 && checkType.propertyFlags.rawValue & properties == properties {
        return UInt32(index)
      }
    }

    throw VulkanApplicationError.noSuitableMemoryType 
  }

  func beginSingleTimeCommands() throws -> CommandBuffer {
    let commandBuffer = try CommandBuffer.allocate(device: device, info: CommandBufferAllocateInfo(
      commandPool: commandPool,
      level: .primary,
      commandBufferCount: 1
    ))
    commandBuffer.begin(CommandBufferBeginInfo(
      flags: .oneTimeSubmit, inheritanceInfo: nil
    ))

    return commandBuffer
  }

  func endSingleTimeCommands(commandBuffer: CommandBuffer) throws {
    commandBuffer.end()

    try queue.submit(submits: [SubmitInfo(
      waitSemaphores: [],
      waitDstStageMask: nil,
      commandBuffers: [commandBuffer],
      signalSemaphores: []
    )], fence: nil)
    queue.waitIdle()

    CommandBuffer.free(commandBuffers: [commandBuffer], device: device, commandPool: commandPool)
  }

  func copyBuffer(srcBuffer: Buffer, dstBuffer: Buffer, size: DeviceSize) throws {
    let commandBuffer = try beginSingleTimeCommands()
    commandBuffer.copyBuffer(srcBuffer: srcBuffer, dstBuffer: dstBuffer, regions: [BufferCopy(
      srcOffset: 0, dstOffset: 0, size: size 
    )])
    try endSingleTimeCommands(commandBuffer: commandBuffer)
  }

  func createImage(
    width: UInt32,
    height: UInt32,
    format: Format,
    tiling: ImageTiling,
    usage: ImageUsageFlags,
    properties: MemoryPropertyFlags) throws -> (Image, DeviceMemory) {
      let image = try Image.create(withInfo: ImageCreateInfo(
        flags: .none,
        imageType: .type2D,
        format: format,
        extent: Extent3D(width: width, height: height, depth: 1),
        mipLevels: 1,
        arrayLayers: 1,
        samples: ._1bit,
        tiling: tiling,
        usage: usage,
        sharingMode: .exclusive,
        queueFamilyIndices: nil,
        initialLayout: .undefined
      ), device: device)

      let memRequirements = image.memoryRequirements

      let memory = try DeviceMemory.allocateMemory(inDevice: device, allocInfo: MemoryAllocateInfo(
        allocationSize: memRequirements.size,
        memoryTypeIndex: try findMemoryType(typeFilter: memRequirements.memoryTypeBits, properties: MemoryPropertyFlags.deviceLocal.rawValue)
      ))

      try image.bindMemory(memory: memory)

      return (image, memory)
  }

  func transitionImageLayout(image: Image, format: Format, oldLayout: ImageLayout, newLayout: ImageLayout) throws {
    let commandBuffer = try beginSingleTimeCommands()

    var barrier = ImageMemoryBarrier(
      srcAccessMask: [],
      dstAccessMask: [],
      oldLayout: oldLayout,
      newLayout: newLayout,
      srcQueueFamilyIndex: VK_QUEUE_FAMILY_IGNORED,
      dstQueueFamilyIndex: VK_QUEUE_FAMILY_IGNORED,
      image: image,
      subresourceRange: ImageSubresourceRange(
        aspectMask: .color,
        baseMipLevel: 0,
        levelCount: 1,
        baseArrayLayer: 0,
        layerCount: 1
      ))
    
    let sourceStage: PipelineStageFlags
    let destinationStage: PipelineStageFlags

    if oldLayout == .undefined && newLayout == .transferDstOptimal {
      barrier.srcAccessMask = []
      barrier.dstAccessMask = .transferWrite

      sourceStage = .topOfPipe
      destinationStage = .transfer
    } else if oldLayout == .transferDstOptimal && newLayout == .shaderReadOnlyOptimal {
      barrier.srcAccessMask = .transferWrite
      barrier.dstAccessMask = .shaderRead

      sourceStage = .transfer
      destinationStage = .fragmentShader
    } else {
      throw VulkanApplicationError.unsupportedImageLayoutTransition(old: oldLayout, new: newLayout)
    }

    commandBuffer.pipelineBarrier(
      srcStageMask: sourceStage, 
      dstStageMask: destinationStage, 
      dependencyFlags: [],
      memoryBarriers: [],
      bufferMemoryBarriers: [],
      imageMemoryBarriers: [barrier]
    )

    try endSingleTimeCommands(commandBuffer: commandBuffer)
  }

  func copyBufferToImage(buffer: Buffer, image: Image, width: UInt32, height: UInt32) throws {
    let commandBuffer = try beginSingleTimeCommands()

    let region = BufferImageCopy(
      bufferOffset: 0,
      bufferRowLength: 0,
      bufferImageHeight: 0,
      imageSubresource: ImageSubresourceLayers(
        aspectMask: .color,
        mipLevel: 0,
        baseArrayLayer: 0,
        layerCount: 1
      ),
      imageOffset: Offset3D(x: 0, y: 0, z: 0),
      imageExtent: Extent3D(width: width, height: height, depth: 1)
    )
    commandBuffer.copyBufferToImage(srcBuffer: buffer, dstImage: image, dstImageLayout: .transferDstOptimal, regions: [region])

    try endSingleTimeCommands(commandBuffer: commandBuffer)
  }

  func createDepthResources() throws {
    // TODO: probably depthFormat should be chosen according to support,
    // as shown in tutorial
    let depthFormat = Format.D32_SFLOAT

    (depthImage, depthImageMemory) = try createImage(
      width: swapchainExtent.width,
      height: swapchainExtent.height,
      format: depthFormat,
      tiling: .optimal,
      usage: .depthStencilAttachment,
      properties: .deviceLocal)

    depthImageView = try createImageView(image: depthImage, format: depthFormat, aspectFlags: .depth)
  }

  func createGUI() throws {
    gui = GUI()
  }

  func createGUISurface() throws {
    guiSurface = SwiftGUI.CpuBufferDrawingSurface(size: ISize2(Int(swapchainExtent.width), Int(swapchainExtent.height)))
    gui.surface = guiSurface
  }

  func createTextureImage() throws {
    //let image = try CpuImage(contentsOf: Bundle.module.url(forResource: "viking_room", withExtension: "png")!)
    let imageWidth = guiSurface.size.width
    let imageHeight = guiSurface.size.height
    let channelCount = 4 
    //let imageDataSize = imageWidth * imageHeight * channelCount
    let dataSize = Int(guiSurface.size.width * guiSurface.size.height * 4)

    gui.update()
    //let skiaDrawnDataPointer = testDraw(Int32(imageWidth), Int32(imageHeight))
    //let image = CpuImage(width: 200, height: 200, rgba: Array(repeating: 255, count: imageDataSize))

    let (stagingBuffer, stagingBufferMemory) = try createBuffer(
      size: DeviceSize(dataSize), usage: [.transferSrc], properties: [.hostVisible, .hostCoherent])
    
    var dataPointer: UnsafeMutableRawPointer? = nil
    try stagingBufferMemory.mapMemory(offset: 0, size: DeviceSize(dataSize), flags: .none, data: &dataPointer)
    dataPointer?.copyMemory(from: guiSurface.buffer, byteCount: dataSize)
    stagingBufferMemory.unmapMemory()

    (textureImage, textureImageMemory) = try createImage(
      width: UInt32(imageWidth),
      height: UInt32(imageHeight),
      format: .R8G8B8A8_SRGB /* note */,
      tiling: .optimal,
      usage: [.transferDst, .sampled],
      properties: [.hostVisible, .hostCoherent])

    try transitionImageLayout(image: textureImage, format: .R8G8B8A8_SRGB /* note */, oldLayout: .undefined, newLayout: .transferDstOptimal)

    try copyBufferToImage(buffer: stagingBuffer, image: textureImage, width: UInt32(imageWidth), height: UInt32(imageHeight))

    try transitionImageLayout(image: textureImage, format: .R8G8B8A8_SRGB /* note */, oldLayout: .transferDstOptimal, newLayout: .shaderReadOnlyOptimal)
  }

  func createTextureImageView() throws {
    textureImageView = try createImageView(image: textureImage, format: .R8G8B8A8_SRGB /* note */, aspectFlags: .color)
  }

  func createTextureSampler() throws {
    textureSampler = try Sampler(device: device, createInfo: SamplerCreateInfo(
      magFilter: .linear,
      minFilter: .linear,
      mipmapMode: .linear,
      addressModeU: .repeat,
      addressModeV: .repeat,
      addressModeW: .repeat,
      mipLodBias: 0,
      anisotropyEnable: true,
      maxAnisotropy: physicalDevice.properties.limits.maxSamplerAnisotropy,
      compareEnable: false,
      compareOp: .always,
      minLod: 0,
      maxLod: 0,
      borderColor: .intOpaqueBlack,
      unnormalizedCoordinates: false
    ))
  }

  func createVertexBuffer(size: DeviceSize) throws {
    (vertexBuffer, vertexBufferMemory) = try createBuffer(
      size: size,
      usage: [.vertexBuffer, .transferDst],
      properties: [.hostVisible, .hostCoherent])
    self.currentVertexBufferSize = size
  }

  func transferVertices(vertices: [Vertex]) throws {
    let vertexData = vertices.flatMap { $0.data }
    let dataSize = DeviceSize(MemoryLayout<Float>.size * vertexData.count)

    if dataSize > currentVertexBufferSize {
      try createVertexBuffer(size: max(currentVertexBufferSize * 2, dataSize))
      device.waitIdle()
      print("recreated vertex buffer with double size because ran out of memory")
    }

    let (stagingBuffer, stagingBufferMemory) = try createBuffer(
      size: dataSize,
      usage: .transferSrc,
      properties: [.hostVisible, .hostCoherent])

    var cpuVertexBufferMemory: UnsafeMutableRawPointer? = nil
    try stagingBufferMemory.mapMemory(offset: 0, size: dataSize, flags: .none, data: &cpuVertexBufferMemory)
    cpuVertexBufferMemory!.copyMemory(from: vertexData, byteCount: MemoryLayout<Float>.size * vertexData.count)
    stagingBufferMemory.unmapMemory()

    try copyBuffer(srcBuffer: stagingBuffer, dstBuffer: vertexBuffer, size: dataSize)

    stagingBuffer.destroy()
    stagingBufferMemory.free()
  }

  func createIndexBuffer(size: DeviceSize) throws {
    if (_indexBuffer.value != nil && _indexBufferMemory.value != nil) {
      print("HERE", indexBuffer)
      indexBuffer.destroy()
      print("HERE")
    }
    (indexBuffer, indexBufferMemory) = try createBuffer(size: size, usage: [.transferDst, .indexBuffer], properties: [.deviceLocal])
    self.currentIndexBufferSize = size
  }

  func transferVertexIndices(indices: [UInt32]) throws {
    let dataSize = DeviceSize(MemoryLayout.size(ofValue: indices[0]) * indices.count)

    if dataSize > currentIndexBufferSize {
      try createIndexBuffer(size: max(currentIndexBufferSize * 2, dataSize))
      print("recreated index buffer with double size because ran out of memory")
    }

    let (stagingBuffer, stagingBufferMemory) = try createBuffer(size: dataSize, usage: .transferSrc, properties: [.hostVisible, .hostCoherent])

    var dataPointer: UnsafeMutableRawPointer? = nil
    try stagingBufferMemory.mapMemory(offset: 0, size: dataSize, flags: .none, data: &dataPointer)
    dataPointer?.copyMemory(from: indices, byteCount: Int(dataSize))
    stagingBufferMemory.unmapMemory()

    try copyBuffer(srcBuffer: stagingBuffer, dstBuffer: indexBuffer, size: dataSize)

    stagingBuffer.destroy()
    stagingBufferMemory.free()
  }

  func updateRenderData(gameObjects: [GameObject]) throws {
    /*try objMesh.load()
    objMesh.modelTransformation = FMat4([
      1, 0, 0, 0,
      0, 1, 0, 10, 
      0, 0, 1, 0,
      0, 0, 0, 1
    ])
    objMesh.rotationQuaternion = Quaternion(angle: 35, axis: FVec3(0, 0, 1))

    cubeMesh.modelTransformation = FMat4([
      1, 0, 0, 0,
      0, 1, 0, 4,
      0, 0, 1, 0,
      0, 0, 0, 1
    ])
    cubeMesh.rotationQuaternion = Quaternion(angle: 15, axis: FVec3(1, 0, 0))
    let meshes: [Mesh] = [cubeMesh, objMesh, planeMesh]

    for mesh in meshes {
      let newVertices = mesh.transformedVertices
      let newIndices = mesh.indices.map {
        $0 + UInt32(vertices.count)
      }
      
      vertices.append(contentsOf: newVertices)
      indices.append(contentsOf: newIndices)
    }*/
    vertices = []
    indices = []

    for gameObject in gameObjects {
      if let meshGameObject = gameObject as? MeshGameObject {
        let newVertices: [Vertex] = meshGameObject.mesh.vertices.map {
          let transformedPosition = FVec3(Array(gameObject.transformation.matmul(FVec4($0.position.elements + [1])).elements[0..<3]))
          return Vertex(position: transformedPosition, color: $0.color, texCoord: $0.texCoord)
        }
        let newIndices = meshGameObject.mesh.indices.map {
          $0 + UInt32(vertices.count)
        }
        
        vertices.append(contentsOf: newVertices)
        indices.append(contentsOf: newIndices)
      }
    }

    if vertices.count == 0 || indices.count == 0 {
      return
    }

    try transferVertices(vertices: vertices)
    try transferVertexIndices(indices: indices)

    CommandBuffer.free(commandBuffers: commandBuffers, device: device, commandPool: commandPool)
    try self.createCommandBuffers()
  }

  func createUniformBuffers() throws {
    let bufferSize = DeviceSize(UniformBufferObject.dataSize)

    uniformBuffers = []
    uniformBuffersMemory = []
    
    for _ in 0..<swapchainImages.count {
      let (buffer, bufferMemory) = try createBuffer(size: bufferSize, usage: .uniformBuffer, properties: [.hostVisible, .hostCoherent])
      uniformBuffers.append(buffer)
      uniformBuffersMemory.append(bufferMemory)
    }
  }

  func createDescriptorPool() throws {
    descriptorPool = try DescriptorPool.create(device: device, createInfo: DescriptorPoolCreateInfo(
      flags: .none,
      maxSets: UInt32(swapchainImages.count),
      poolSizes: [
        DescriptorPoolSize(
          type: .uniformBuffer, descriptorCount: UInt32(swapchainImages.count)
        ),
        DescriptorPoolSize(
          type: .combinedImageSampler, descriptorCount: UInt32(swapchainImages.count)
        )
      ]
    ))
  }

  func createDescriptorSets() throws {
    descriptorSets = DescriptorSet.allocate(device: device, allocateInfo: DescriptorSetAllocateInfo(
        descriptorPool: descriptorPool,
        descriptorSetCount: UInt32(swapchainImages.count),
        setLayouts: Array(repeating: descriptorSetLayout, count: swapchainImages.count)))
    
    for i in 0..<swapchainImages.count {
      let bufferInfo = DescriptorBufferInfo(
        buffer: uniformBuffers[i], offset: 0, range: DeviceSize(UniformBufferObject.dataSize)
      )

      /*let imageInfo = DescriptorImageInfo(
        sampler: textureSampler, imageView: textureImageView, imageLayout: .shaderReadOnlyOptimal 
      )*/

      let descriptorWrites = [
        WriteDescriptorSet(
          dstSet: descriptorSets[i],
          dstBinding: 0,
          dstArrayElement: 0,
          descriptorCount: 1,
          descriptorType: .uniformBuffer,
          imageInfo: [],
          bufferInfo: [bufferInfo],
          texelBufferView: []),
        /*WriteDescriptorSet(
          dstSet: descriptorSets[i],
          dstBinding: 1,
          dstArrayElement: 0,
          descriptorCount: 1,
          descriptorType: .combinedImageSampler,
          imageInfo: [imageInfo],
          bufferInfo: [],
          texelBufferView: [])*/
      ]

      device.updateDescriptorSets(descriptorWrites: descriptorWrites, descriptorCopies: nil)
    }
  }

  func createCommandBuffers() throws {
    self.commandBuffers = try framebuffers.enumerated().map { (index, framebuffer) in
      let commandBuffer = try CommandBuffer.allocate(device: device, info: CommandBufferAllocateInfo(
        commandPool: commandPool,
        level: .primary,
        commandBufferCount: 1))

      commandBuffer.begin(CommandBufferBeginInfo(
        flags: [],
        inheritanceInfo: nil))

      commandBuffer.beginRenderPass(beginInfo: RenderPassBeginInfo(
        renderPass: renderPass,
        framebuffer: framebuffer,
        renderArea: Rect2D(
          offset: Offset2D(x: 0, y: 0), extent: swapchainExtent
        ),
        clearValues: [
          ClearColorValue.float32(0, 0, 0, 1).eraseToAny(),
          ClearDepthStencilValue(depth: 1, stencil: 0).eraseToAny()]
      ), contents: .inline)

      commandBuffer.bindPipeline(pipelineBindPoint: .graphics, pipeline: graphicsPipeline)

      commandBuffer.bindVertexBuffers(firstBinding: 0, buffers: [vertexBuffer], offsets: [0])
      commandBuffer.bindIndexBuffer(buffer: indexBuffer, offset: 0, indexType: VK_INDEX_TYPE_UINT32)

      commandBuffer.bindDescriptorSets(
        pipelineBindPoint: .graphics,
        layout: pipelineLayout,
        firstSet: 0,
        descriptorSets: [descriptorSets[index], materialSystem.materialRenderData[ObjectIdentifier(mainMaterial)]!.descriptorSets[index]],
        dynamicOffsets: [])
      commandBuffer.drawIndexed(indexCount: UInt32(indices.count), instanceCount: 1, firstIndex: 0, vertexOffset: 0, firstInstance: 0)

      commandBuffer.endRenderPass()
      commandBuffer.end()

      return commandBuffer
    }
  }

  func createSyncObjects() throws {
    imageAvailableSemaphores = try (0..<maxFramesInFlight).map { _ in 
      try Semaphore.create(info: SemaphoreCreateInfo(
        flags: .none
      ), device: device)
    }

    renderFinishedSemaphores = try (0..<maxFramesInFlight).map { _ in 
      try Semaphore.create(info: SemaphoreCreateInfo(
        flags: .none
      ), device: device)
    }

    inFlightFences = try (0..<maxFramesInFlight).map { _ in
      try Fence(device: device, createInfo: FenceCreateInfo(
        flags: [.signaled]
      ))
    }
  }

  func recreateSwapchain() throws {
    if window.size.width == 0 || window.size.height == 0 {
      return
    }
    /*var windowWidth: Int32 = 0
    var windowHeight: Int32 = 0
    SDL_GetWindowSize(window, &windowWidth, &windowHeight)
    var event = SDL_Event()
    while windowWidth == 0 || windowHeight == 0 {
      SDL_WaitEvent(&event)
      SDL_GetWindowSize(window, &windowWidth, &windowHeight)
    }*/

    device.waitIdle()

    try createSwapchain()
    try createImageViews()
    try createRenderPass()
    try createGraphicsPipeline()
    try createDepthResources()
    try createFramebuffers()
    try createUniformBuffers()
    try createDescriptorPool()
    try createDescriptorSets()
    try createCommandBuffers()
  }

  func cleanupSwapchain() {
    depthImageView.destroy()
    depthImage.destroy()
    depthImageMemory.destroy()
    framebuffers.forEach { $0.destroy() }
    CommandBuffer.free(commandBuffers: commandBuffers, device: device, commandPool: commandPool)
    graphicsPipeline.destroy()
    renderPass.destroy()
    imageViews.forEach { $0.destroy() }
    swapchain.destroy()

    for i in 0..<uniformBuffers.count {
      uniformBuffers[i].destroy()
      uniformBuffersMemory[i].free()
    }

    descriptorPool.destroy()
  }

  func drawFrame() throws {
    gui.update()

    let imageAvailableSemaphore = imageAvailableSemaphores[currentFrameIndex]
    let renderFinishedSemaphore = renderFinishedSemaphores[currentFrameIndex]
    let inFlightFence = inFlightFences[currentFrameIndex]

    inFlightFence.wait(timeout: .max)

    let (imageIndex, acquireImageResult) = try swapchain.acquireNextImage(timeout: .max, semaphore: imageAvailableSemaphore, fence: nil)

    if acquireImageResult == .errorOutOfDateKhr {
      device.waitIdle()
      queue.waitIdle()
      cleanupSwapchain()
      try recreateSwapchain()
      return
    } else if acquireImageResult != .success && acquireImageResult != .suboptimalKhr {
      throw UnexpectedVulkanResultError(acquireImageResult)
    }

    if let previousFence = imagesInFlightWithFences[imageIndex] {
      previousFence.wait(timeout: .max)
    }
    imagesInFlightWithFences[imageIndex] = inFlightFence
    inFlightFence.reset()

    let timestamp = Date.timeIntervalSinceReferenceDate
    let progress = timestamp.truncatingRemainder(dividingBy: 2) / 2
    //camera.yaw = Float(progress * 360)
    //camera.pitch = Float(progress * 360)
    try updateUniformBuffer(currentImage: imageIndex)

    try queue.submit(submits: [
      SubmitInfo(
        waitSemaphores: [imageAvailableSemaphore],
        waitDstStageMask: [.colorAttachmentOutput],
        commandBuffers: [commandBuffers[Int(imageIndex)]],
        signalSemaphores: [renderFinishedSemaphore]
      )
    ], fence: inFlightFence)

    let presentResult = queue.present(presentInfo: PresentInfoKHR(
      waitSemaphores: [renderFinishedSemaphore],
      swapchains: [swapchain],
      imageIndices: [imageIndex],
      results: ()
    ))

    if presentResult == .errorOutOfDateKhr || presentResult == .suboptimalKhr {
      device.waitIdle()
      queue.waitIdle()
      cleanupSwapchain()
      try recreateSwapchain()
      return
    } else if presentResult != .success {
      throw UnexpectedVulkanResultError(acquireImageResult)
    }

    currentFrameIndex += 1
    currentFrameIndex %= maxFramesInFlight
  }

  func updateUniformBuffer(currentImage: UInt32) throws {
    /*var windowWidth: Int32 = 0
    var windowHeight: Int32 = 0
    SDL_GetWindowSize(window, &windowWidth, &windowHeight)*/
    let aspectRatio = Float(window.size.width) / Float(window.size.height)

    let uniformBufferObject = UniformBufferObject(
      model: FMat4.identity/*newRotation(yaw: 0, pitch: 0)*/.matmul(FMat4([
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
      ])),
      view: camera.viewMatrix.transposed,
      projection: FMat4.newProjection(
        aspectRatio: aspectRatio, fov: 90, near: 0.1, far: 100).transposed)

    var dataPointer: UnsafeMutableRawPointer? = nil
    try uniformBuffersMemory[Int(currentImage)].mapMemory(
      offset: 0,
      size: DeviceSize(UniformBufferObject.dataSize),
      flags: .none,
      data: &dataPointer)
    dataPointer?.copyMemory(from: uniformBufferObject.data, byteCount: UniformBufferObject.dataSize)
    uniformBuffersMemory[Int(currentImage)].unmapMemory()
  }

  /*func mainLoop() throws {
    /*var event = SDL_Event()
    event.type = 0
    while SDL_PollEvent(&event) != 0 {
      if event.type == SDL_QUIT.rawValue {
        device.waitIdle()
        exit(0)
      } else if event.type == SDL_KEYDOWN.rawValue {
        let speed = Float(0.5)

        if event.key.keysym.sym == SDLK_UP {
          camera.position += camera.forward * speed
        } else if event.key.keysym.sym == SDLK_DOWN {
          camera.position -= camera.forward * speed
        } else if event.key.keysym.sym == SDLK_RIGHT {
          camera.position += camera.right * speed
        } else if event.key.keysym.sym == SDLK_LEFT {
          camera.position -= camera.right * speed
        } else if event.key.keysym.sym == SDLK_ESCAPE {
          SDL_SetRelativeMouseMode(SDL_FALSE)
        }

      } else if event.type == SDL_MOUSEMOTION.rawValue {
        camera.yaw += Float(event.motion.xrel)
        camera.pitch -= Float(event.motion.yrel)
        camera.pitch = min(89, max(-89, camera.pitch))
      } else if event.type == SDL_MOUSEBUTTONDOWN.rawValue {
        SDL_SetRelativeMouseMode(SDL_TRUE)
      }
    }*/
    
    //try drawFrame()
  }*/

  func destroy() {
    //vertexBuffer.destroy()
  }
} 

public enum VulkanApplicationError: Error {
  case noSuitableQueueFamily,
    noSuitableMemoryType,
    unsupportedImageLayoutTransition(old: ImageLayout, new: ImageLayout)
}

public struct UnexpectedVulkanResultError: Error {
  public let result: Result 

  public init(_ result: Result) {
    self.result = result
  }
}