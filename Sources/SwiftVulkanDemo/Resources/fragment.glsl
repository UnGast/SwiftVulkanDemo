#version 450
#extension GL_ARB_separate_shader_objects:enable

layout(set = 1, binding = 0) uniform sampler2D texSampler;

layout(location=0) in vec4 fragColor;
layout(location=1) in vec2 fragTexCoord;

layout(location=0) out vec4 outColor;

void main() {
  vec4 tmpOutColor = texture(texSampler, fragTexCoord) + fragColor * 0.2;
  if (tmpOutColor[3] == 0) {
    discard;
  }
  outColor = tmpOutColor;
}