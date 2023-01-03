#version 330 core
layout(location=0) in vec2 a_position;
layout(location=1) in vec2 a_texcoord;

uniform mat4 u_transform;

out vec2 v2f_texcoord;

void main() {
	gl_Position = u_transform * vec4(a_position, 1.0, 1.0);
    v2f_texcoord = a_texcoord;
}
