#version 330 core
layout(location=0) in vec3 a_position;

uniform vec4 u_color;
uniform mat4 u_transform;

out vec4 v2f_color;

void main() {
	gl_Position = u_transform * vec4(a_position, 1.0);
    v2f_color = u_color;
}
