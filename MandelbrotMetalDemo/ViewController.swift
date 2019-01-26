//Copyright (c) 2018 Patrick Sturm <psturm-swift@e.mail.de>
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.

import Cocoa
import MetalKit

class ViewController: NSViewController {
    var mandelbrotView: MTKView!
    var device: MTLDevice!
    var vertexBuffer: MTLBuffer!
    var mandelbrotVertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initDevice()
        initMandelbrotView()
        initBuffers()
        initPipelineState()
        initCommandQueue()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        let drawable = view.currentDrawable!
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        let black = MTLClearColor(
            red: 0.0,
            green: 0.0,
            blue: 0.0,
            alpha: 1.0)
        
        renderPassDescriptor.colorAttachments[0].clearColor = black
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(mandelbrotVertexBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

fileprivate extension ViewController {
    private func initDevice() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("MetalKit: Cannot create device")
        }
        self.device = device
    }

    private func initMandelbrotView() {
        self.mandelbrotView = MTKView()
        self.mandelbrotView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self.mandelbrotView)
        self.mandelbrotView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.mandelbrotView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        self.mandelbrotView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        self.mandelbrotView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        self.mandelbrotView.device = self.device
        self.mandelbrotView.colorPixelFormat = .bgra8Unorm
        self.mandelbrotView.delegate = self
    }
    
    private func initBuffers() {
        let vertices: [Float] = [
            -1.0, -1.0,
            -1.0,  1.0,
             1.0, -1.0,
             1.0,  1.0
        ]
        
        // -2.0/-1.0 +1.0/+1.0
        let mandelbrotVertices: [Float] = [
            -2.0, -1.0,
            -2.0,  1.0,
             1.0, -1.0,
             1.0,  1.0
        ]
        
        let bytesVertices = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        let bytesMandelbrotVertices = mandelbrotVertices.count * MemoryLayout.size(ofValue: mandelbrotVertices[0])
        
        vertexBuffer = device.makeBuffer(bytes: vertices, length: bytesVertices, options: [])
        mandelbrotVertexBuffer = device.makeBuffer(bytes: mandelbrotVertices, length: bytesMandelbrotVertices, options: [])
    }
    
    private func initPipelineState() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Cannot create library")
        }
        
        let vertexShader = library.makeFunction(name: "vertexShader")
        let fragmentShader = library.makeFunction(name: "mandelbrotFragment")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexShader
        pipelineStateDescriptor.fragmentFunction = fragmentShader
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    private func initCommandQueue() {
        self.commandQueue = device.makeCommandQueue()
    }
}
