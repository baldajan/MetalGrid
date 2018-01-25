//
//  BlurKernel.metal
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Basil Al-Dajane. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


kernel void k_quarter_down(texture2d<float, access::read>  inTexture  [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           ushort2 tid [[thread_position_in_grid]])
{
    ushort2 gid = ushort2(tid.x * 4, tid.y * 4);
    
    int radius = 4;
    float numOfPoints = radius * radius;
    
    float3 totalcolor = float3(0.0, 0.0, 0.0);
    
    for (int j=0; j < radius; ++j) {
        for (int i=0; i < radius; ++i) {
            totalcolor += inTexture.read(uint2(gid.x + i, gid.y + j)).rgb;
        }
    }
    
    float3 averagecolor = totalcolor / float3(numOfPoints, numOfPoints, numOfPoints);
    outTexture.write(float4(averagecolor, 1), static_cast<uint2>(ushort2(tid.x, tid.y)));
}


kernel void k_gaussian_blur(texture2d<float, access::read>  inTexture  [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            texture2d<float, access::read>  weights    [[texture(2)]],
                            ushort2 gid [[thread_position_in_grid]])
{
    int size = weights.get_width();
    int radius = size / 2;
    
    float4 accumColor(0, 0, 0, 0);
    
    for (int j = 0; j < size; ++j) {
        for (int i = 0; i < size; ++i) {
            uint2 kernelIndex(i, j);
            uint2 textureIndex(gid.x + (i - radius), gid.y + (j - radius));
            float4 color = inTexture.read(textureIndex).rgba;
            float4 weight = weights.read(kernelIndex).rrrr;
            accumColor += weight * color;
        }
    }
    
    outTexture.write(float4(accumColor.rgb, 1), gid);
}


//kernel void k_gaussian_blur(texture2d<float, access::read>  inTexture  [[texture(0)]],
//                            texture2d<float, access::write> outTexture [[texture(1)]],
//                            texture2d<float, access::read>  weights    [[texture(2)]],
//                            ushort2 tid [[thread_position_in_grid]])
//{
//    ushort2 gid = ushort2(tid.x * 2, tid.y);
//
//    int size = weights.get_width();
//    int radius = size / 2;
//
//    float3 accumColor0(0, 0, 0);
//    float3 accumColor1(0, 0, 0);
//
//    for (int j = 0; j < size; ++j) {
//        for (int i = 1; i < size; ++i) {
//            uint2 textureIndex(gid.x + (i - radius), gid.y + (j - radius));
//            float3 color = inTexture.read(textureIndex).rgb;
//
//            accumColor0 += weights.read(uint2(i,   j)).rrr * color;
//            accumColor1 += weights.read(uint2(i-1, j)).rrr * color;
//        }
//
//        {   // Grab left edge for first and third pixel
//            uint2 textureIndex(gid.x - radius, gid.y + (j - radius));
//            float3 color = inTexture.read(textureIndex).rgb;
//            accumColor0 += weights.read(uint2(0, j)).rrr * color;
//        }
//
//        {   // Grab right edge for second and third  pixel
//            uint2 textureIndex(gid.x + (size - radius), gid.y + (j - radius));
//            float3 color = inTexture.read(textureIndex).rgb;
//            accumColor1 += weights.read(uint2(size-1, j)).rrr * color;
//        }
//    }
//
//    outTexture.write(float4(accumColor0, 1), static_cast<uint2>(ushort2(gid.x,   gid.y)));
//    outTexture.write(float4(accumColor1, 1), static_cast<uint2>(ushort2(gid.x+1, gid.y)));
//}




