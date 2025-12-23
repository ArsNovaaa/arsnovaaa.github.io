// normal_mapping.glsl - 法线贴图实现，包含切线计算

// 顶点着色器
#version 450 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aTexCoords;
layout (location = 3) in vec3 aTangent;
layout (location = 4) in vec3 aBitangent;

out VS_OUT {
    vec3 FragPos;
    vec2 TexCoords;
    mat3 TBN;
} vs_out;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    vs_out.FragPos = vec3(model * vec4(aPos, 1.0));
    vs_out.TexCoords = aTexCoords;
    
    // 计算TBN矩阵
    vec3 T = normalize(vec3(model * vec4(aTangent, 0.0)));
    vec3 B = normalize(vec3(model * vec4(aBitangent, 0.0)));
    vec3 N = normalize(vec3(model * vec4(aNormal, 0.0)));
    
    // 正交化处理
    T = normalize(T - dot(T, N) * N);
    
    // 构建TBN矩阵
    vs_out.TBN = mat3(T, B, N);
    
    gl_Position = projection * view * model * vec4(aPos, 1.0);
}

// 片段着色器
#version 450 core
out vec4 FragColor;

in VS_OUT {
    vec3 FragPos;
    vec2 TexCoords;
    mat3 TBN;
} fs_in;

uniform sampler2D diffuseMap;
uniform sampler2D normalMap;

uniform vec3 lightPos;
uniform vec3 viewPos;

void main()
{
    // 从法线贴图获取法线（切线空间）
    vec3 normal = texture(normalMap, fs_in.TexCoords).rgb;
    // 将法线从[0,1]转换到[-1,1]
    normal = normalize(normal * 2.0 - 1.0);
    
    // 将法线转换到世界空间
    normal = normalize(fs_in.TBN * normal);
    
    // 漫反射计算
    vec3 color = texture(diffuseMap, fs_in.TexCoords).rgb;
    vec3 lightDir = normalize(lightPos - fs_in.FragPos);
    float diff = max(dot(lightDir, normal), 0.0);
    vec3 diffuse = diff * color;
    
    // 镜面反射计算
    vec3 viewDir = normalize(viewPos - fs_in.FragPos);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
    vec3 specular = spec * vec3(0.2);
    
    FragColor = vec4(diffuse + specular, 1.0);
}

// 如果没有预计算的切线数据，可以使用以下函数在CPU端计算
/*
void calculateTangentAndBitangent(Mesh& mesh) {
    for (size_t i = 0; i < mesh.indices.size(); i += 3) {
        Vertex& v0 = mesh.vertices[mesh.indices[i]];
        Vertex& v1 = mesh.vertices[mesh.indices[i+1]];
        Vertex& v2 = mesh.vertices[mesh.indices[i+2]];
        
        vec3 edge1 = v1.Position - v0.Position;
        vec3 edge2 = v2.Position - v0.Position;
        vec2 deltaUV1 = v1.TexCoords - v0.TexCoords;
        vec2 deltaUV2 = v2.TexCoords - v0.TexCoords;
        
        float f = 1.0f / (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y);
        
        vec3 tangent;
        tangent.x = f * (deltaUV2.y * edge1.x - deltaUV1.y * edge2.x);
        tangent.y = f * (deltaUV2.y * edge1.y - deltaUV1.y * edge2.y);
        tangent.z = f * (deltaUV2.y * edge1.z - deltaUV1.y * edge2.z);
        
        vec3 bitangent;
        bitangent.x = f * (-deltaUV2.x * edge1.x + deltaUV1.x * edge2.x);
        bitangent.y = f * (-deltaUV2.x * edge1.y + deltaUV1.x * edge2.y);
        bitangent.z = f * (-deltaUV2.x * edge1.z + deltaUV1.x * edge2.z);
        
        v0.Tangent = tangent;
        v1.Tangent = tangent;
        v2.Tangent = tangent;
        
        v0.Bitangent = bitangent;
        v1.Bitangent = bitangent;
        v2.Bitangent = bitangent;
    }
}
*/
