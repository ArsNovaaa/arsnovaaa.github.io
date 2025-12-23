---
layout: post
title: Shadow Mapping原理与OpenGL 4.50+实现
date: 2025-7-8 10:00 +0800
last_modified_at: 2025-7-8 10:00 +0800
tags: [Rendering, OpenGL, Shadow]
toc:  true
math: true
---

## Shadow Mapping原理

Shadow Mapping是一种基于深度缓冲的实时阴影渲染技术，主要分为两个阶段：

1. **深度图生成阶段**：从光源视角渲染场景，生成深度纹理（Shadow Map）
2. **阴影渲染阶段**：从相机视角渲染场景，比较当前片段深度与Shadow Map中的深度值

### 数学原理

对于场景中的一点P，判断其是否在阴影中的条件：

$$
\text{Shadow}(P) = 
\begin{cases} 
1, & \text{if } z_P > z_{\text{shadow}}(P_{light}) + \text{bias} \\
0, & \text{otherwise}
\end{cases}
$$

其中：
- $z_P$是当前片段在光源空间中的深度
- $z_{\text{shadow}}(P_{light})$是Shadow Map中存储的深度值
- bias是用于解决自遮挡问题的偏移量

## OpenGL 4.50+实现流程

### 1. 创建深度纹理

```cpp
GLuint depthMapFBO, depthMap;
glGenFramebuffers(1, &depthMapFBO);

// 创建2D纹理作为深度缓冲
glGenTextures(1, &depthMap);
glBindTexture(GL_TEXTURE_2D, depthMap);
glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32F, 
             SHADOW_WIDTH, SHADOW_HEIGHT, 0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

// 配置FBO
glBindFramebuffer(GL_FRAMEBUFFER, depthMapFBO);
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthMap, 0);
glDrawBuffer(GL_NONE);
glReadBuffer(GL_NONE);
glBindFramebuffer(GL_FRAMEBUFFER, 0);
```

### 2. 深度图生成Pass

```cpp
// 设置光源空间变换矩阵
glm::mat4 lightProjection = glm::ortho(-10.0f, 10.0f, -10.0f, 10.0f, 1.0f, 7.5f);
glm::mat4 lightView = glm::lookAt(lightPos, glm::vec3(0.0f), glm::vec3(0.0, 1.0, 0.0));
glm::mat4 lightSpaceMatrix = lightProjection * lightView;

// 渲染到深度纹理
glViewport(0, 0, SHADOW_WIDTH, SHADOW_HEIGHT);
glBindFramebuffer(GL_FRAMEBUFFER, depthMapFBO);
glClear(GL_DEPTH_BUFFER_BIT);

depthShader.use();
depthShader.setMat4("lightSpaceMatrix", lightSpaceMatrix);
RenderScene(depthShader);

glBindFramebuffer(GL_FRAMEBUFFER, 0);
```

### 3. 阴影渲染Pass（使用OpenGL 4.50特性）

```cpp
// 使用计算着色器进行PCF（Percentage Closer Filtering）
GLuint pcfShader = createComputeShader("pcf.comp");

glBindImageTexture(0, depthMap, 0, GL_FALSE, 0, GL_READ_ONLY, GL_R32F);
glUseProgram(pcfShader);
glDispatchCompute((SHADOW_WIDTH + 7)/8, (SHADOW_HEIGHT + 7)/8, 1);
glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);

// 主渲染
glViewport(0, 0, SCR_WIDTH, SCR_HEIGHT);
glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

shader.use();
shader.setMat4("lightSpaceMatrix", lightSpaceMatrix);
glActiveTexture(GL_TEXTURE1);
glBindTexture(GL_TEXTURE_2D, depthMap);
RenderScene(shader);
```

### 4. 计算着色器示例（PCF实现）

```glsl
#version 450 core
layout(local_size_x = 8, local_size_y = 8) in;
layout(binding = 0, r32f) uniform readonly image2D shadowMap;
layout(binding = 1, rgba32f) uniform writeonly image2D pcfResult;

uniform float texelSize;
uniform float bias;

void main() {
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
    float shadow = 0.0;
    
    for(int x = -1; x <= 1; ++x) {
        for(int y = -1; y <= 1; ++y) {
            float depth = imageLoad(shadowMap, texelCoord + ivec2(x, y)).r;
            shadow += (gl_FragCoord.z - bias > depth) ? 1.0 : 0.0;
        }
    }
    
    shadow /= 9.0;
    imageStore(pcfResult, texelCoord, vec4(vec3(shadow), 1.0));
}
```

## 多光源Shadow Map管理

### 1. 使用纹理数组(GL_TEXTURE_2D_ARRAY)

```cpp
// 创建纹理数组存储多个平行光的shadow map
GLuint shadowArray;
glGenTextures(1, &shadowArray);
glBindTexture(GL_TEXTURE_2D_ARRAY, shadowArray);
glTexImage3D(GL_TEXTURE_2D_ARRAY, 0, GL_DEPTH_COMPONENT32F,
             SHADOW_WIDTH, SHADOW_HEIGHT, MAX_LIGHTS,
             0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);

// 为每个光源创建FBO并绑定到纹理数组的不同层
for (int i = 0; i < MAX_LIGHTS; ++i) {
    glGenFramebuffers(1, &lightFBOs[i]);
    glBindFramebuffer(GL_FRAMEBUFFER, lightFBOs[i]);
    glFramebufferTextureLayer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, 
                            shadowArray, 0, i);
}
```

### 2. 点光源的立方体贴图(GL_TEXTURE_CUBE_MAP)

```cpp
GLuint pointShadowCube;
glGenTextures(1, &pointShadowCube);
glBindTexture(GL_TEXTURE_CUBE_MAP, pointShadowCube);

for (int i = 0; i < 6; ++i) {
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_DEPTH_COMPONENT,
                SHADOW_WIDTH, SHADOW_HEIGHT, 0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);
}

// 使用几何着色器一次渲染6个面
glFramebufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, pointShadowCube, 0);
```

### 3. 计算着色器统一管理

```glsl
#version 450
layout(local_size_x = 16, local_size_y = 16) in;
layout(binding = 0) uniform sampler2DArray shadowArray;
layout(binding = 1) uniform samplerCube pointShadows;

void main() {
    // 处理多个光源的阴影
    for (int i = 0; i < activeLights; ++i) {
        if (lightTypes[i] == DIRECTIONAL) {
            float shadow = texture(shadowArray, vec3(uv, i)).r;
            // ...
        } else if (lightTypes[i] == POINT) {
            float shadow = texture(pointShadows, lightDir).r;
            // ...
        }
    }
}
```

## 优化与问题解决

1. **PCSS（Percentage Closer Soft Shadows）**：
   - 根据遮挡物距离动态调整滤波核大小
   - 使用OpenGL 4.50的计算着色器高效实现

2. **VSM（Variance Shadow Maps）**：
   ```cpp
   // 使用GL_RG32F格式存储深度和深度平方
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RG32F, width, height, 0, GL_RG, GL_FLOAT, NULL);
   ```

3. **级联阴影（CSM）**：
   - 使用几何着色器实现多视锥分割
   - 每个级联使用不同的Shadow Map

