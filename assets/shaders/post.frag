#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform sampler2D visibilityShape;

out vec4 finalColor;

void main()
{
    vec4 texelColor = texture(texture0, fragTexCoord)*colDiffuse*fragColor;
    finalColor = texelColor;
    finalColor.r = texture(visibilityShape, fragTexCoord).r;
}
