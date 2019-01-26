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

#include <metal_stdlib>
using namespace metal;

struct Mapping {
    float4 position [[position]];
    float2 complexNumber;
};

vertex Mapping vertexShader(uint vertexID [[vertex_id]],
                            const device packed_float2 *vertices [[buffer(0)]],
                            const device packed_float2 *complexVertices [[buffer(1)]]) {
    Mapping mapping;
    mapping.position = float4(vertices[vertexID], 0.0, 1.0);
    mapping.complexNumber = complexVertices[vertexID];
    
    return mapping;
}

fragment half4 mandelbrotFragment(Mapping mapping [[stage_in]]) {
    const int maxDepth = 200;
    float cReal = mapping.complexNumber.x;
    float cImag = mapping.complexNumber.y;
    int depth = 0;
    float zReal = 0.0;
    float zImag = 0.0;

    do {
        const float temp = zReal * zReal - zImag * zImag + cReal;
        zImag = 2.0 * zReal * zImag + cImag;
        zReal = temp;
        depth++;
    } while (zReal * zReal + zImag * zImag < 1000.0 && depth < maxDepth);
    
    return (depth >= maxDepth)
        ? half4(0.0, 0.0, 0.0, 1.0)
        : mix(half4(1.0, 0.0, 0.0, 1.0), half4(0.0, 0.0, 1.0, 1.0), (sin(depth / 5.0) + 1.0) / 2.0);
}
