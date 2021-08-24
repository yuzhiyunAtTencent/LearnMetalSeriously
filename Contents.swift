import PlaygroundSupport
import MetalKit

//https://zhuanlan.zhihu.com/p/384158800
//https://www.raywenderlich.com/books/metal-by-tutorials/v2.0/chapters/1-hello-metal#toc-chapter-004-anchor-001

guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("metal is not supported")
}

let frame = CGRect(x: 0, y: 0, width: 600, height: 600)
let view = MTKView(frame: frame, device: device)
view.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 1)

// 1
let allocator = MTKMeshBufferAllocator(device: device)
// 2
// 创建一个球体，三个参数代表球体的半径：xyz,如果三个半径相等，就会等于一个圆球体，否则是椭圆球
// segments 貌似代表点的密集度
let mdlMesh = MDLMesh(coneWithExtent: [1, 1, 1],
                      segments: [10, 10],
                      inwardNormals: false,
                      cap: true,
                      geometryType: .triangles,
                      allocator: allocator)
// 3
let mesh = try MTKMesh(mesh: mdlMesh, device: device)

guard let commandQueue = device.makeCommandQueue() else {
  fatalError("Could not create a command queue")
}

let shader = """
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
  float4 position [[ attribute(0) ]];
};

vertex float4 vertex_main(const VertexIn vertex_in [[ stage_in ]]) {
  return vertex_in.position;
}

fragment float4 fragment_main() {
  return float4(1, 0, 0, 1);
}
"""

let library = try device.makeLibrary(source: shader, options: nil)
let vertexFunction = library.makeFunction(name: "vertex_main")
let fragmentFunction = library.makeFunction(name: "fragment_main")

let pipelineDescriptor = MTLRenderPipelineDescriptor()
pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
pipelineDescriptor.vertexFunction = vertexFunction
pipelineDescriptor.fragmentFunction = fragmentFunction
pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)

// 创建piplineState是一个耗时行为
//Creating pipeline states is relatively time-consuming
let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

// 1
guard let commandBuffer = commandQueue.makeCommandBuffer(),
// 2
let renderPassDescriptor = view.currentRenderPassDescriptor,
// 3
let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
    fatalError()
}

renderEncoder.setRenderPipelineState(pipelineState)

renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)

guard let submesh = mesh.submeshes.first else {
  fatalError()
}

// 显示三角形的三条边，如果不加这行代码，就会显示成实心
renderEncoder.setTriangleFillMode(.lines)

//.triangle代表显示成实心的，.point就会显示成一个个点
renderEncoder.drawIndexedPrimitives(type: .triangle,
                          indexCount: submesh.indexCount,
                          indexType: submesh.indexType,
                          indexBuffer: submesh.indexBuffer.buffer,
                          indexBufferOffset: 0)

// 1
renderEncoder.endEncoding()
// 2
guard let drawable = view.currentDrawable else {
  fatalError()
}
// 3
commandBuffer.present(drawable)
commandBuffer.commit()

PlaygroundPage.current.liveView = view






