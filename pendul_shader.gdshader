shader_type canvas_item;

uniform float zoom = 1.0;
uniform vec2 offset = vec2(0.0, 0.0);

uniform float g = 9.80665;
uniform float L1 = 2.2; // Lungimile tijelor
uniform float L2 = 1.3;
uniform float m1 = 1.2; // Masele obiectelor
uniform float m2 = 1.7;

uniform int steps = 1200; 
uniform float dt = 0.0025;

// Vitezele unghiulare initiale (rad/s)
uniform float OM10 = -0.52359; // aprox -30 grade
uniform float OM20 = 0.34906;  // aprox 20 grade

uniform int function = 0;

// Recunosc, asta e direct din gemini
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 function0(float theta1, float theta2) {
    vec4 col;
    col.r = 0.5 + 0.5 * sin(theta1);
    col.g = 0.5 + 0.5 * cos(theta2);
    col.b = 0.5 + 0.5 * sin(theta1 - theta2);
    col.a = 1.0;
    return col;
}

vec4 function1(float theta1, float theta2) {
    float h = fract(theta1 / (2.0 * PI)); // formulele sunt din gemini
    float s = 0.5 + 0.5 * sin(theta2);
    float v = 0.5 + 0.5 * cos(theta2);
    
    vec3 rgb = hsv2rgb(vec3(h, s, v));
    return vec4(rgb, 1.0);
}

// In functie de cat de apropiat este de punctele de maxim stanga, jos, dreapta si sus
// contribuim cu rosu, verge, albastru, respectiv alb, interpoland liniar intre
// doua cele mai apropiate dintre aceste puncte
// Intunecam culoarea cu cat e mai aproape de mijloc
vec4 function2(float theta1, float theta2) {
    // Coordonate carteziene
    float x = L1 * sin(theta1) + L2 * sin(theta2);
    float y = -L1 * cos(theta1) - L2 * cos(theta2);
    
    // Normalizam
    float L_max = L1 + L2;
    float nx = x / L_max;
    float ny = y / L_max;
    
    float r_val = max(-nx, 0.0); // Stânga
    float b_val = max(nx, 0.0);  // Dreapta
    float g_val = max(ny, 0.0); // Sus

    vec3 col = vec3(
        r_val,
        g_val,
        b_val
    );
    
    return vec4(col, 1.0);
}

vec4 function3(int esc_step) {
    // Daca nu s-a rasturnat, coloram cu negru
    if (esc_step == steps) {
        return vec4(0.0, 0.0, 0.0, 1.0); 
    }
    
    float t = float(esc_step) / float(steps);
    float intensity = 1.0 - t;
    
    // Gradient de foc: Alb -> Galben -> Portocaliu -> Rosu -> Negru (chatgpt)
    vec3 col = vec3(
        smoothstep(0.0, 0.3, intensity), // Roșu apare repede
        smoothstep(0.3, 0.7, intensity), // Verdele se combină la mijloc pentru galben
        smoothstep(0.7, 1.0, intensity)  // Albastrul apare doar la extremă pentru alb
    );
    
    return vec4(col, 1.0);
}

vec4 function4(int esc_step) {
    // Daca nu s-a rasturnat, coloram cu negru
    if (esc_step == steps) {
        return vec4(0.0, 0.0, 0.0, 1.0); 
    }
    
    float t = float(esc_step) / float(steps);
    t = sqrt(log(t + 1.0) / log(2.0));
    float intensity = 1.0 - t;
    
    // Gradient de foc: Alb -> Galben -> Portocaliu -> Rosu -> Negru (chatgpt)
    vec3 col = vec3(
        smoothstep(0.0, 0.3, intensity), // Roșu apare repede
        smoothstep(0.3, 0.7, intensity), // Verdele se combină la mijloc pentru galben
        smoothstep(0.7, 1.0, intensity)  // Albastrul apare doar la extremă pentru alb
    );
    
    return vec4(col, 1.0);
}

vec4 function5(float om1, float om2) {
    float total_velocity = abs(om1) + abs(om2);

    // Multumim lui chatgpt pentru ajutor cu partea estetica

    // Normalizăm folosind o scară logaritmică pentru a evidenția contrastele.
    // Valoarea divizorul este arbitrar ales pentru a calibra intensitatea.
    // Poate fi ajustat (ex: mai mic pentru a face imaginea mai roșie, mai mare pentru mai albastră).
    float t = clamp(log(total_velocity + 0.5) / 3.5, 0.0, 1.0);

    vec3 col_calm  = vec3(0.0, 0.0, 0.0); // Negru (viteză mică/stabil); 0.0
    vec3 col_med1  = vec3(0.0, 1.0, 0.7); // Cyan                                ; 0.1
    vec3 col_med2  = vec3(0.0, 0.0, 1.0); // Verde                               ; 0.3
    vec3 col_med3  = vec3(1.0, 1.0, 0.0); // Galben                              ; 0.6
    vec3 col_chaos = vec3(1.0, 0.0, 0.0); // Roșu (viteză mare/haos)             ; 1.0

    vec3 final_color;
    if (t < 0.1) {
        final_color = mix(col_calm, col_med1, t * 10.0);
    } else if (t < 0.3) {
        final_color = mix(col_med1, col_med2, (t - 0.1) * 5.0);
    } else if (t < 0.6) {
        final_color = mix(col_med2, col_med3, (t - 0.3) * 3.3333333333);
    } else {
        final_color = mix(col_med3, col_chaos, (t - 0.6) * 2.5);
    }

    return vec4(final_color, 1.0);
}

void fragment() {
	vec2 transformed_uv = (UV - 0.5) * zoom + 0.5 + offset;
	
    // UV (0.0 -> 1.0) => unghiurile inițiale (-PI -> PI)
    float theta10 = (transformed_uv.x - 0.5) * 2.0 * PI;
    float theta20 = (transformed_uv.y - 0.5) * 2.0 * PI;

    float theta1 = theta10 + OM10 * dt;
    float theta2 = theta20 + OM20 * dt;
    float theta1_prev = theta10;
    float theta2_prev = theta20;

    // Coeficienți constanți
    float miu = 1.0 + m1 / m2;
    float r = L1 / L2;
    float a11 = r * miu;
    float a22 = 1.0 / r;

    int escape_step = steps;

    for (int i = 0; i < steps; i++) {
        float aux = theta2 - theta1;
        float a12 = cos(aux);
        float a21 = a12;

        float om1 = (theta1 - theta1_prev) / dt;
        float om2 = (theta2 - theta2_prev) / dt;

        float b1 = om2 * om2 * sin(aux) - (g / L2) * miu * sin(theta1);
        float b2 = -om1 * om1 * sin(aux) - (g / L1) * sin(theta2);

        // Cramer
        float det = a11 * a22 - a12 * a21;
        float eps1 = (b1 * a22 - b2 * a12) / det;
        float eps2 = (a11 * b2 - a21 * b1) / det;

        float t1_next = 2.0 * theta1 - theta1_prev + dt * dt * eps1;
        float t2_next = 2.0 * theta2 - theta2_prev + dt * dt * eps2;

        theta1_prev = theta1;
        theta2_prev = theta2;
        theta1 = t1_next;
        theta2 = t2_next;

        if (function == 3 || function == 4) {
            if (abs(theta1 - theta10) > 2.0 * PI || abs(theta2 - theta20) > 2.0 * PI) {
                escape_step = i;
                break;
            }
        }
    }

    vec4 col;
    if (function == 0) {
        col = function0(theta1, theta2);
    } else if (function == 1) {
        col = function1(theta1, theta2);
    } else if (function == 2) {
        col = function2(theta1, theta2);
    } else if (function == 3) {
        col = function3(escape_step);
    } else if (function == 4) {
        col = function4(escape_step);
    } else if (function == 5) {
        col = function5((theta1 - theta1_prev) / dt, (theta2 - theta2_prev) / dt);
    }

    COLOR = col;
}