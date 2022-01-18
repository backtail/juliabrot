#version 150 core

// depiction variables
vec2 z = vec2(0.0, 0.0);
vec2 c = vec2(0.0, 0.0);
uniform float zoom;
uniform float c_x;
uniform float c_y;
vec2 c_complex = vec2(c_x, c_y);
uniform int max_iterations;

// color palette and algorithms variables
uniform int color_algorithm;
float color_offset = 0.0;
float color_range = 0.08;

// window variables
uniform int width;
uniform int height;
vec2 w_dimension = vec2(width, height);

// julia or mandelbrot
uniform int set;
uniform int fractal_algorithm;

// main color output
out vec4 color;

//-----------------------------------
// Complex numbers utility
//-----------------------------------

/**
 *
 * Complex math functions
 *
        ((a.x*a.x)+(a.y*a.y))

    from Johan Karlsson
    found here: https://github.com/julesb/glsl-util/blob/master/complexvisual.glsl
 */

#define PI 3.14159265
#define TWOPI (2.0*PI)

#define cx_add(a, b) vec2(a.x + b.x, a.y + b.y)
#define cx_sub(a, b) vec2(a.x - b.x, a.y - b.y)
#define cx_mul(a, b) vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x)
#define cx_div(a, b) vec2(((a.x*b.x+a.y*b.y)/(b.x*b.x+b.y*b.y)),((a.y*b.x-a.x*b.y)/(b.x*b.x+b.y*b.y)))
#define cx_modulus(a) length(a)
#define cx_conj(a) vec2(a.x,-a.y)
#define cx_arg(a) atan(a.y,a.x)
#define cx_sin(a) vec2(sin(a.x) * cosh(a.y), cos(a.x) * sinh(a.y))
#define cx_cos(a) vec2(cos(a.x) * cosh(a.y), -sin(a.x) * sinh(a.y))

vec2 cx_to_polar(vec2 a) {
    float phi = atan(a.x, a.y);
    float r = sqrt(a.x * a.x + a.y * a.y);
    return vec2(r, phi);
}

vec2 cx_sqrt(vec2 a) {
    float r = sqrt(a.x * a.x + a.y * a.y);
    float rpart = sqrt(0.5 * (r + a.x));
    float ipart = sqrt(0.5 * (r - a.x));
    if(a.y < 0.0)
        ipart = -ipart;
    return vec2(rpart, ipart);
}

vec2 cx_tan(vec2 a) {
    return cx_div(cx_sin(a), cx_cos(a));
}

vec2 cx_log(vec2 a) {
    float rpart = sqrt((a.x * a.x) + (a.y * a.y));
    float ipart = atan(a.y, a.x);
    if(ipart > PI)
        ipart = ipart - (2.0 * PI);
    return vec2(log(rpart), ipart);
}

vec2 cx_mobius(vec2 a) {
    vec2 c1 = a - vec2(1.0, 0.0);
    vec2 c2 = a + vec2(1.0, 0.0);
    return cx_div(c1, c2);
}

vec2 cx_z_plus_one_over_z(vec2 a) {
    return a + cx_div(vec2(1.0, 0.0), a);
}

vec2 cx_z_squared_plus_c(vec2 z, vec2 c) {
    return cx_mul(z, z) + c;
}

vec2 cx_sin_of_one_over_z(vec2 z) {
    return cx_sin(cx_div(vec2(1.0, 0.0), z));
}

//-----------------------------------
// Misc ultility
//-----------------------------------

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float log10(float num) {
    return log(num) / log(10.0);
}

//-----------------------------------
// Coloring algorithms
//-----------------------------------

void linear_coloring(float iterations) {
    if(iterations == max_iterations) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        float val = iterations / float(max_iterations);
        color = vec4(hsv2rgb(vec3(val, 1.0, 1.0)), 1.0);
    }
}

void smooth_coloring(float iterations, vec2 z) {
    if(iterations == max_iterations) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        float val = iterations + 1.0 - log10(log10(length(z))) / log10(2.0);
        val = val * (1.0 / float(max_iterations));
        color = vec4(hsv2rgb(vec3(val, 1.0, 1.0)), 1.0);
    }
}

void shady_patterns(float iterations, vec2 z) {
    if(iterations == max_iterations) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        float min_step = iterations / float(max_iterations);
        float val = min_step + 1.0 - log(log(length(z))) / log(2.0);
        val = color_offset + val * color_range;
        color = vec4(hsv2rgb(vec3(val, 1.0, 1.0)), 1.0);
    }
}

//-----------------------------------
// Fractal algorithms
//-----------------------------------

void naive_mandelbrot(inout float iterations, inout vec2 z, inout vec2 c) {
    for(iterations = 0.0; iterations < max_iterations; iterations++) {
        z = cx_mul(z, z) + c;
        if(length(z) > 2.0) {
            break;
        }
    }
}

// cool points
// re: 0.0062482357, im: 0.559965
void mobius_squared(inout float iterations, inout vec2 z, inout vec2 c) {
    for(iterations = 0.0; iterations < max_iterations; iterations++) {
        z = cx_mobius(cx_mul(z, z) + c);
        if(length(z) > 4.0) {
            break;
        }
    }
}

// cool points
// re: 0.11892238, im: 0.4829234
void mobius_cubed(inout float iterations, inout vec2 z, inout vec2 c) {
    for(iterations = 0.0; iterations < max_iterations; iterations++) {
        z = cx_mobius(cx_mul(cx_mul(z, z), z) + c);
        if(length(z) > 2.0) {
            break;
        }
    }
}

void mobius_z_squared(inout float iterations, inout vec2 z, inout vec2 c) {
    for(iterations = 0.0; iterations < max_iterations; iterations++) {
        z = cx_mobius(cx_mul(z, z)) + c;
        if(length(z) > 2.0) {
            break;
        }
    }
}

void mobius_z_cubed(inout float iterations, inout vec2 z, inout vec2 c) {
    for(iterations = 0.0; iterations < max_iterations; iterations++) {
        z = cx_mobius(cx_mul(cx_mul(z, z), z)) + c;
        if(length(z) > 2.0) {
            break;
        }
    }
}

void weird_new(inout float iterations, inout vec2 z, inout vec2 c) {
    for(iterations = 0.0; iterations < max_iterations; iterations++) {
        vec2 z2 = vec2(0.0, 0.0);
        z2 = z.xy * z.xy;
        z.y = sin((z.x + z.x) * z.y) + tan(c.y);
        z.x = (z2.x - z2.y) + log(sin((1.618*(c.x * z.y)/128.0)));
        if(z2.x + z2.y > 50.0) {
            break;
        }
    }
}

//-----------------------------------
// Main Loop
//-----------------------------------

void main() {

    float iterations;

    switch(set) {
        case 0:
        // Mandelbrot Set
            c = c_complex.xy + ((gl_FragCoord.xy / float(w_dimension.xy)) - 0.5) * zoom;
            z = c;
            break;
        case 1:
        // Julia Set
            z = ((gl_FragCoord.xy / float(w_dimension.xy)) - 0.5) * zoom;
            c = c_complex;
            break;
    }

    switch(fractal_algorithm) {
        case 0:
            naive_mandelbrot(iterations, z, c);
            break;
        case 1:
            mobius_squared(iterations, z, c);
            break;
        case 2:
            mobius_cubed(iterations, z, c);
            break;
        case 3:
            mobius_z_squared(iterations, z, c);
            break;
        case 4:
            mobius_z_cubed(iterations, z, c);
            break;
    }

    //mobius_squared(iterations, z, c);

    switch(color_algorithm) {
        case 0:
            linear_coloring(iterations);
            break;
        case 1:
            smooth_coloring(iterations, z);
            break;
        case 2:
            shady_patterns(iterations, z);
            break;
    }
}
