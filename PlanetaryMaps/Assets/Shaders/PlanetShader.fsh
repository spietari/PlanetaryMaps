#version 300 es

precision highp float;

out vec4 fragmentColor;
in vec2 texCoord;

uniform vec4 lineColor;
uniform float lineSpacing;

uniform float dist;
uniform mat4 rot;

const float pi   = 3.1415926536;
const float pi_18 = 0.1745329252;

uniform float planetSizeMultiplier;

void main()
{
    float x =  texCoord.x * planetSizeMultiplier;
    float y = -texCoord.y * planetSizeMultiplier;
    
    float sinLatitude = y;
    float cosLatitude = sqrt(1.0 - sinLatitude * sinLatitude);
    float sinLongitude = x / cosLatitude;
    float cosLongitude = sqrt(1.0 - sinLongitude * sinLongitude);
    
    vec4 rot_eye = rot * vec4(cosLatitude * cosLongitude, cosLatitude * sinLongitude, sinLatitude, 0);
    
    float latitude =  atan(rot_eye.z, sqrt(rot_eye.y * rot_eye.y + rot_eye.x * rot_eye.x));
    float longitude = atan(rot_eye.y, rot_eye.x);
    
    fragmentColor = vec4(0, 0, 0, 0);
    
    float lineWidth = dist * 0.004;
    
    float d_lon = sign(lineWidth / cos(latitude) - mod(longitude, pi_18 * lineSpacing / 10.0));
    float d_lat = sign(lineWidth - mod(latitude, pi_18 * lineSpacing / 10.0));
    
    d_lon = clamp(d_lon, 0.0, 1.0);
    d_lat = clamp(d_lat, 0.0, 1.0);
    
    fragmentColor = lineColor * max(d_lon, d_lat) * lineColor.a;
    fragmentColor.a = 1.0;
}
