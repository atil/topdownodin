#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform sampler2D visibilityShape;

out vec4 finalColor;

void main() {
    //vec4 visCol = texture(visibilityShape, fragTexCoord);
    finalColor = texture(texture0, fragTexCoord) * fragColor;
    // finalColor = mix(visCol, finalColor, 0.01);
}
