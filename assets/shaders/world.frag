#version 330 core

in vec2 v2f_texcoord;

uniform sampler2D u_texture;

out vec4 out_color;

void main() {
	out_color = texture(u_texture, v2f_texcoord);
}
