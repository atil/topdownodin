#version 330 core

in vec2 v2f_texcoord;

uniform sampler2D u_texture;
uniform vec4 u_color;

out vec4 out_color;

void main() {
	/* float alpha = texture(u_texture, v2f_texcoord).r; */
    /* out_color = vec4(u_color.rgb, alpha); */
    out_color = texture(u_texture, v2f_texcoord);
}
