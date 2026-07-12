#version 460
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_ARB_separate_shader_objects : enable

layout(location = 0) in vec2 fragTexCoord;
layout(location = 1) flat in uint fragTexIndex;
layout(location = 2) flat in uint samplerIndex;
layout(location = 3) in vec3 view_TBN;

layout(set = 0, binding = 0) uniform texture2D textures[];
layout(set = 0, binding = 1) uniform writeonly image2D images[];
layout(set = 0, binding = 2) uniform sampler samplers[1];
layout(set = 0, binding = 2) uniform samplerShadow shadowSamplers[1];

layout(location = 0) out vec4 outColor;

#define PI 3.1415926538

float sinc(float x) {
    if (abs(x) < 1e-4) {
        return 1.0 - (x * x) * 0.16666667; // 0.16666667 是 1/6
    }
    return sin(x) / x;
}

float Phi(float x) {
    float abs_x = abs(x);
    
    float t = 1.0 / (1.0 + 0.2316419 * abs_x);
    float d = 0.39894228 * exp(-0.5 * x * x); // 0.39894228 = 1/sqrt(2*pi)
    
    float p = d * t * (0.31938153 + t * (-0.356563782 + t * (1.781477937 + t * (-1.821255978 + t * 1.330274429))));
    
    return x >= 0.0 ? (1.0 - p) : p;
}

float EvaluateG(float q1, float q2, float mu, float sigma) {
    // float inv_sigma = 1.0 / max(sigma, 1e-5); 
    
    float z2 = (q2 - mu) / max(sigma, 1e-5);
    float z1 = (q1 - mu) / max(sigma, 1e-5);
    
    float p1 = Phi(z2);
    float p2 = Phi(z1);

    return p1 - p2;
}

float Gauss(float s, float sigma_s, float sigma_s_pow2, float mean_s) {
    float pi_2 = sigma_s * sqrt(PI * 2);
    float s_m_pow2 = pow(abs(s - mean_s), 2);
    float exp_power = -1 * s_m_pow2 / (2 * sigma_s_pow2);

    return (1 / pi_2) * exp(exp_power);
}

float F_p(float v) {
    return -0.97867503 * v * v * v + 2.60238128 * v * v + -1.88083816 * v + 0.77743396;
}

float F_p_Der(float v) {
    return -0.97867503 * 3 * v * v + 2.60238128 * 2 * v + -1.88083816;
}

vec2 RachisMasking(float theta, float radius, vec2 v_proj, vec2 r, float centerLine, float e) {
    float cos_theta = dot(v_proj, r);
    float abs_cos_theta = abs(cos_theta);

    float W_proj = 2 * radius / max(abs_cos_theta + e, 0.1);
    
    float W_quote = sqrt(pow(abs(W_proj / 2), 2.0) + pow(abs(radius * tan(theta)), 2)) - W_proj / 2;
    
    float r_quote = (W_proj + W_quote) * abs_cos_theta * 0.5;
    r_quote = min(r_quote, radius * 3.0);

    // float c_quote = centerLine + sign(cos_theta) * (W_proj / 2) * r.x;
    float c_quote = centerLine;

    return vec2(r_quote, c_quote);
}

vec2 BarbMasking(float theta, float radius, vec2 v_proj, vec2 r, float centerLine, float e, float spacing) {
    float cos_theta = dot(v_proj, r);
    float abs_cos_theta = abs(cos_theta);

    float W_proj = 2 * radius / (abs_cos_theta + e);
    
    float W_quote_1 = sqrt(pow(abs(W_proj / 2), 2.0) + pow(abs(radius * tan(theta)), 2)) - W_proj / 2;

    float W_quote_2 = spacing / abs_cos_theta - W_proj;

    float W_quote = min(W_quote_1, W_quote_2);
    
    float r_quote = (W_proj + W_quote) * abs_cos_theta * 0.5;

    float c_quote = centerLine + sign(cos_theta) * (W_proj / 2);
    //  * r.x;

    return vec2(r_quote, c_quote);
}

float I_barbule(float phase, float s_l, float s_r, float sigma_s, float sigma_s_pow2,
                float mean_s, float mean_t, float a, float b, float r_bl, float sigma_st,
                float sigma_t_s) {
    const float x[3] = {-0.77459667, 0.0, 0.77459667};
    const float w[3] = {0.55555556, 0.88888889, 0.55555556};

    float minus_half = (s_r - s_l) / 2;

    float res = 0.0;

    for (int i = 0;i < 3;i++) {
        float s = minus_half * x[i] + (s_r + s_l) / 2;

        float mean_t_s = mean_t + sigma_st / sigma_s_pow2 * (s - mean_s);
                                        
        float g = Gauss(s, sigma_s, sigma_s_pow2, mean_s);
        
        float v1 = (phase - a * s - r_bl) / b;
        float v2 = (phase - a * s + r_bl) / b;

        float f1 = min(v1, v2);
        float f2 = max(v1, v2);

        float gg = EvaluateG(f1, f2, mean_t_s, sigma_t_s);
        
        res += w[i] * g * gg;
    }

    return minus_half * res;
}

float Overlap(float phase_d, float phase_p, float s_l, float s_r, float sigma_s, float sigma_s_pow2,
                float mean_s, float mean_t, float a_d, float b_d, float a_p, float b_p, float r_bd,
                float r_bp,float sigma_st, float sigma_t_s) {
    const float x[3] = {-0.77459667, 0.0, 0.77459667};
    const float w[3] = {0.55555556, 0.88888889, 0.55555556};

    float minus_half = (s_r - s_l) / 2;

    float res = 0.0;

    for (int i = 0;i < 3;i++) {
        float s = minus_half * x[i] + (s_r + s_l) / 2;

        float mean_t_s = mean_t + sigma_st / sigma_s_pow2 * (s - mean_s);
                                        
        float g = Gauss(s, sigma_s, sigma_s_pow2, mean_s);
        
        float v1_d = (phase_d - a_d * s - r_bd) / b_d;
        float v2_d = (phase_d - a_d * s + r_bd) / b_d;

        float f1_d = min(v1_d, v2_d);
        float f2_d = max(v1_d, v2_d);

        float v1_p = (phase_p - a_p * s - r_bp) / b_p;
        float v2_p = (phase_p - a_p * s + r_bp) / b_p;

        float f1_p = min(v1_p, v2_p);
        float f2_p = max(v1_p, v2_p);

        float f1 = max(f1_d, f1_p);
        float f2 = min(f2_d, f2_p);

        float gg = EvaluateG(f1, f2, mean_t_s, sigma_t_s);
        if (gg < 0) gg = 0;
        
        res += w[i] * g * gg;
    }

    return minus_half * res;
}

void main() {
    
    // outColor = vec4(1.0, 1.0, 1.0, 1.0);

    // rachis, barb, barblue radius
    float r_r = 400; // um
    float r_b = 25;
    float r_bl = 3.5;

    // barblue spacing
    float d_bl = 14;

    // feather width
    float width = 40000;

    // radius in uv space
    float r_r_uv = r_r / width;
    float r_b_uv = r_b / width;
    float r_bl_uv = r_bl / width;
    float d_bl_uv = d_bl / width;

    float sigma = 0.5;
    float sigma_0 = 1e-2;

    // barb orientation angle
    float a_b = radians(35);

    // barbule angle offset w.r.t. the barb
    float a_bl = radians(45);

    // barb count along the rachis
    int N_b = 400;

    // barb period
    float p_b = sin(a_b) / N_b;
    float p_bl = d_bl_uv * sin(a_bl);

    vec2 mean_original = fragTexCoord;
    float u = mean_original.x;
    float v = mean_original.y;

    float x = u - F_p(v) + 0.5;
    float y = v;

    vec2 mean =vec2(x, y);

    float flip = x > 0.5 ? -1 : 1;

    vec3 view_dir = normalize(view_TBN);

    // barb direction,  barb normal
    vec2 direction_b = vec2(-sin(a_b) * flip, cos(a_b));
    vec2 normal_b = vec2(cos(a_b) * flip, sin(a_b));
    
    vec2 n_bd = vec2(cos(a_b - a_bl) * flip, sin(a_b - a_bl));
    vec2 n_bp = vec2(cos(a_b + a_bl) * flip, sin(a_b + a_bl));

    float a_bd = dot(n_bd, normal_b);
    float b_bd = dot(n_bd, direction_b);

    float a_bp = dot(n_bp, normal_b);
    float b_bp = dot(n_bp, direction_b);

    vec2 v_proj = view_dir.xy / max(length(view_dir.xy), 1e-5); 
    float theta = acos(clamp(view_dir.z, -1.0, 1.0));

    float dUx = dFdx(fragTexCoord.x);
    float dUy = dFdy(fragTexCoord.x);
    float dVx = dFdx(fragTexCoord.y);
    float dVy = dFdy(fragTexCoord.y);
    
    mat2x2 J_uv = mat2x2(dUx, dUy, 
                    dVx, dVy);

    mat2x2 Sigma_uv = sigma * sigma * J_uv * transpose(J_uv) + 
                    sigma_0 * sigma_0 * mat2x2(1);

    // float dXx = dUx - F_p_Der(v) * dVx;
    // float dXy = dUy - F_p_Der(v) * dVy;
    // float dYx = dVx;
    // float dYy = dVy;

    mat2x2 J = mat2x2(
        1.0, 0.0,
        -F_p_Der(v), 1.0);

    mat2x2 Sigma = J * Sigma_uv * transpose(J);
    float sigma_x = sqrt(Sigma[0][0]);

    float sigma_s_pow2 = dot(normal_b, Sigma * normal_b);
    float sigma_s = sqrt(sigma_s_pow2);

    float sigma_st = dot(normal_b, Sigma * direction_b);

    float sigma_t_pow2 = dot(direction_b, Sigma * direction_b);

    float sigma_t_s = sqrt(sigma_t_pow2 - sigma_st * sigma_st / sigma_s_pow2);

    vec2 res = RachisMasking(theta, r_r_uv, v_proj, vec2(1, 0), 0.5, 0.00005);
    float r_r_uv_ = res.x;
    float c_r_ = res.y; 
    float w_r = EvaluateG(c_r_ - r_r_uv_, c_r_ + r_r_uv_, x, sigma_x);

    mat2x2 M = mat2x2(normal_b.x, direction_b.x, normal_b.y, direction_b.y);

    vec2 mean_z = M * mean;

    float w_b = 0.0;
    float w_bd = 0.0;
    float w_bp = 0.0;

    bool far = sigma_s > 2 * p_b ? true : false;

    if (far) {
        float threshold = 3.0;
        
        const float g_0 = 0.01;
            
        vec2 masking_b = BarbMasking(theta, r_b_uv, v_proj, normal_b, g_0, 0.00005, p_b);
        float r_b_eff = masking_b.x; 

        const float L_Q = p_b - 2.0 * r_b_eff;

        const float phase_bd_0 = 0.0;
        const float phase_bp_0 = 0.0;

        const float q_0 = r_b_eff;

        // barb
        vec2 U_b = (2 * PI / p_b) * normal_b;

        float A_b = dot(U_b, Sigma * U_b);
        int k_g_b_max = int(ceil(sqrt(2 * threshold / A_b)));
        int k_g_b_min = -k_g_b_max;

        for (int i = k_g_b_min;i <= k_g_b_max;i++) {
            float omega_kg_b = 2 * PI * i / p_b;

            vec2 omega_b = omega_kg_b * normal_b;

            float l1 = (2 * masking_b.x / p_b) * sinc(omega_kg_b * masking_b.x);
            float l2 = exp(-0.5 * dot(omega_b, Sigma * omega_b));
            float l3 = cos(omega_kg_b * masking_b.y - dot(omega_b, mean));

            w_b += l1 * l2 * l3;
        }

        //barbule
        float delta_g_bd = p_b * sin(a_b - a_bl) / sin(a_b);
        vec2 U_bd = (2 * PI / p_bl) * n_bd - (2 * PI * delta_g_bd / (p_bl * p_b)) * normal_b;
        vec2 V = (2 * PI / p_b) * normal_b;

        float A_bd = dot(U_bd, Sigma * U_bd);
        float B_bd = dot(U_bd, Sigma * V);
        float C = dot(V, Sigma * V);
        
        float denom = A_bd * C - B_bd * B_bd;

        int k_g_bd_max = int(ceil(sqrt(2 * threshold * C / denom)));
        k_g_bd_max = min(k_g_bd_max, 3);
        int k_g_bd_min = -k_g_bd_max;

        int k_q_bd_max = int(ceil(sqrt(2 * threshold * A_bd / denom)));
        k_q_bd_max = min(k_q_bd_max, 3);
        int k_q_bd_min = -k_q_bd_max;
        
        vec2 masking_bd = BarbMasking(theta, r_bl_uv, v_proj, n_bd, phase_bd_0, 0.00005, p_bl);
        float r_bd_m = masking_bd.x;
        float c_bd_m = masking_bd.y;

        float l1_cache_bd[7][7];
        vec2 omega_cache_bd[7][7];
        float l3_a_cache_bd[7][7];

        for(int g = k_g_bd_min;g <= k_g_bd_max;g++) {
            for(int q = k_q_bd_min;q <= k_q_bd_max;q++) {

                float omega_kg_bd = 2 * PI * g / p_bl;
                float omega_kq_bd = (2 * PI * q - omega_kg_bd * delta_g_bd) / p_b;

                vec2 omega_bd = omega_kg_bd * n_bd + omega_kq_bd * normal_b;
                omega_cache_bd[g + k_g_bd_max][q + k_q_bd_max] = omega_bd;

                float l1 = 2 * r_bd_m * L_Q / (p_bl * p_b) * sinc(omega_kg_bd * r_bd_m) * sinc(omega_kq_bd * L_Q * 0.5);

                l1_cache_bd[g + k_g_bd_max][q + k_q_bd_max] = l1;

                float l2 = exp(- 0.5 * dot(omega_bd, Sigma * omega_bd));

                float l3_a = omega_kg_bd * c_bd_m + omega_kq_bd * q_0 - dot(omega_bd, mean);
                l3_a_cache_bd[g + k_g_bd_max][q + k_q_bd_max] = l3_a;

                float l3 = cos(l3_a);

                w_bd += l1 * l2 * l3;
            }
        }

        float delta_g_bp = p_b * sin(a_b + a_bl) / sin(a_b);
        vec2 U_bp = (2 * PI / p_bl) * n_bp - (2 * PI * delta_g_bp / (p_bl * p_b)) * normal_b;

        float A_bp = dot(U_bp, Sigma * U_bp);
        float B_bp = dot(U_bp, Sigma * V);
        
        float denom_bp = A_bp * C - B_bp * B_bp;

        int k_g_bp_max = int(ceil(sqrt(2 * threshold * C / denom_bp)));
        k_g_bp_max = min(k_g_bp_max, 3);
        int k_g_bp_min = -k_g_bp_max;

        int k_q_bp_max = int(ceil(sqrt(2 * threshold * A_bp / denom_bp)));
        k_q_bp_max = min(k_q_bp_max, 3);
        int k_q_bp_min = -k_q_bp_max;
        
        vec2 masking_bp = BarbMasking(theta, r_bl_uv, v_proj, n_bp, phase_bp_0, 0.00005, p_bl);
        float r_bp_m = masking_bp.x;
        float c_bp_m = masking_bp.y;

        float w_bp_ = 0.0;

        float l1_cache_bp[7][7];
        vec2 omega_cache_bp[7][7];
        float l3_a_cache_bp[7][7];

        for(int g = k_g_bp_min;g <= k_g_bp_max;g++) {
            for(int q = k_q_bp_min;q <= k_q_bp_max;q++) {

                float omega_kg_bp = 2 * PI * g / p_bl;
                float omega_kq_bp = (2 * PI * q - omega_kg_bp * delta_g_bp) / p_b;

                vec2 omega_bp = omega_kg_bp * n_bp + omega_kq_bp * normal_b;
                omega_cache_bp[g + k_g_bp_max][q + k_q_bp_max] = omega_bp;

                float l1 = 2 * r_bp_m * L_Q / (p_bl * p_b) * sinc(omega_kg_bp * r_bp_m) * sinc(omega_kq_bp * L_Q / 2);

                l1_cache_bp[g + k_g_bp_max][q + k_q_bp_max] = l1;

                float l2 = exp(- 0.5 * dot(omega_bp, Sigma * omega_bp));
                
                float l3_a = omega_kg_bp * c_bp_m + omega_kq_bp * q_0 - dot(omega_bp, mean);
                l3_a_cache_bp[g + k_g_bp_max][q + k_q_bp_max] = l3_a;

                float l3 = cos(l3_a);

                w_bp_ += l1 * l2 * l3;
            }
        }

        float overlap = 0.0;

        for(int g_bd = k_g_bd_min;g_bd <= k_g_bd_max;g_bd++) {
            for(int q_bd = k_q_bd_min;q_bd <= k_q_bd_max;q_bd++) {
                for(int g_bp = k_g_bp_min;g_bp <= k_g_bp_max;g_bp++) {
                    for(int q_bp = k_q_bp_min;q_bp <= k_q_bp_max;q_bp++) {
                        vec2 omega = omega_cache_bd[g_bd + k_g_bd_max][q_bd + k_q_bd_max] + 
                                    omega_cache_bp[g_bp + k_g_bp_max][q_bp + k_q_bp_max];

                        float l1 = l1_cache_bd[g_bd + k_g_bd_max][q_bd + k_q_bd_max] *
                                 l1_cache_bp[g_bp + k_g_bp_max][q_bp + k_q_bp_max];

                        float l2 = exp(-0.5 * dot(omega, Sigma * omega));
                        float l3_a = l3_a_cache_bd[g_bd + k_g_bd_max][q_bd + k_q_bd_max] + 
                                    l3_a_cache_bp[g_bp + k_g_bp_max][q_bp + k_q_bp_max];

                        float l3 = cos(l3_a);

                        overlap += l1 * l2 * l3;
                    }
                }
            }
        }

        w_bp = w_bp_ - overlap;
    } else {

        // barb weight
        int m = 4;
        int kb_min = int(ceil((mean_z.x - m * sigma_s) / p_b));
        int kb_max = int(floor((mean_z.x + m * sigma_s) / p_b));

        vec2 s_boundary_array[32];
        int s_count = 0;

        for (int i = kb_min;i <= kb_max;i++) {
            vec2 masking = BarbMasking(theta, r_b_uv, v_proj, normal_b, i * p_b, 0.00005, p_b);

            float r_kb_uv_ = masking.x;
            float c_kb_ = masking.y;

            s_boundary_array[s_count + 1].x = c_kb_;
            s_boundary_array[s_count + 1].y = r_kb_uv_;
            s_count += 1;

            w_b +=  EvaluateG(c_kb_ - r_kb_uv_, c_kb_ + r_kb_uv_, mean_z.x, sigma_s);
        }
        vec2 c_kb1 = BarbMasking(theta, r_b_uv, v_proj, normal_b, (kb_max + 1) * p_b, 0.00005, p_b);
        s_boundary_array[s_count + 1].x = c_kb1.y;
        s_boundary_array[s_count + 1].y = c_kb1.x;
        s_count += 1;

        vec2 c_kb2 = BarbMasking(theta, r_b_uv, v_proj, normal_b, (kb_min - 1) * p_b, 0.00005, p_b);
        s_boundary_array[0].x = c_kb2.y;
        s_boundary_array[0].y = c_kb2.x;
        s_count += 1;

        // barbule weight

        // vec2  P_b = vec2(dot(mean, direction_b), dot(mean, normal_b));

        int delta_k_bl = 2;

        float w_bp_ = 0.0;

        float overlap = 0.0;

        int kg_min = kb_min - 1;
        int kg_max = kb_max;

        for (int j = kg_min, idx = 0;j <= kg_max;j++, idx++) {

            float y_barb_bd = float(j) / float(N_b);
            float phase_base_bd = dot(vec2(0, y_barb_bd), n_bd);

            int k_bd_0 = int(floor((b_bd * mean_z.y + a_bd * mean_z.x - phase_base_bd) / p_bl));
            int k_bd_min = k_bd_0 - delta_k_bl;
            int k_bd_max = k_bd_0 + delta_k_bl;

            float phase_start_bd = k_bd_0 * p_bl + phase_base_bd - delta_k_bl * p_bl;
            float phase_k_bd = phase_start_bd;

            float s_l = s_boundary_array[idx].x + s_boundary_array[idx].y;
            float s_r = s_boundary_array[idx + 1].x - s_boundary_array[idx + 1].y;

            vec2 masking_bd[32];
            int bd_masking_count = 0;

            for (int i = k_bd_min;i <= k_bd_max;i++) {
                vec2 masking = BarbMasking(theta, r_bl_uv, v_proj, n_bd, phase_k_bd, 0.0005, p_bl);

                masking_bd[bd_masking_count] = masking;
                bd_masking_count += 1;

                w_bd += I_barbule(masking.y, s_l, s_r, sigma_s, sigma_s_pow2, mean_z.x, mean_z.y, 
                                a_bd, b_bd, masking.x, sigma_st, sigma_t_s);
                
                phase_k_bd += p_bl;
            }

            float y_barb_bp = float(j + 1) / float(N_b);
            float phase_base_bp = dot(vec2(0, y_barb_bp), n_bp);

            int k_bp_0 = int(floor((b_bp * mean_z.y + a_bp * mean_z.x - phase_base_bp) / p_bl));
            int k_bp_min = k_bp_0 - delta_k_bl;
            int k_bp_max = k_bp_0 + delta_k_bl;

            float phase_start_bp = k_bp_0 * p_bl + phase_base_bp - delta_k_bl * p_bl;
            float phase_k_bp = phase_start_bp;

            vec2 masking_bp[32];
            int bp_masking_count = 0;

            for (int i = k_bp_min;i <= k_bp_max;i++) {
                vec2 masking = BarbMasking(theta, r_bl_uv, v_proj, n_bp, phase_k_bp, 0.0005, p_bl);

                masking_bp[bp_masking_count] = masking;
                bp_masking_count += 1;

                w_bp_ += I_barbule(masking.y, s_l, s_r, sigma_s, sigma_s_pow2, mean_z.x, mean_z.y, 
                                a_bp, b_bp, masking.x, sigma_st, sigma_t_s);
                
                phase_k_bp += p_bl;
            }

            for (int p = k_bp_min, idx1 = 0;p <= k_bp_max;p++, idx1++) {
                for (int d = k_bd_min, idx2 = 0;d <= k_bd_max;d++, idx2++) {
                    overlap += Overlap(masking_bd[idx2].y, masking_bp[idx1].y, s_l, s_r, sigma_s,
                             sigma_s_pow2, mean_z.x, mean_z.y, a_bd, b_bd, a_bp, b_bp, masking_bd[idx2].x,
                             masking_bp[idx1].x, sigma_st, sigma_t_s);
                }
            }
        }

        w_bp = w_bp_ - overlap;
    }

    w_r  = max(w_r,  0.0);
    w_b  = max(w_b,  0.0);
    w_bd = max(w_bd, 0.0);
    w_bp = max(w_bp, 0.0);

    float S = w_r + w_b + w_bd + w_bp;
    float w_t = 0.0;

    if (S > 1.0) {
        w_r /= S;
        w_b /= S;
        w_bd /= S;
        w_bp /= S;
        w_t = 0.0;
    } else {
        w_t = 1.0 - S;
    }

    float alpha = far ? 0.25 : 0.75;

    outColor = vec4(w_t * vec3(1.0, 1.0, 1.0) + 
                    w_r * vec3(1.0, 0.0, 0.0) +
                    w_b * vec3(0.0, 1.0, 0.0) +
                    w_bd * vec3(0.0, 0.0, 1.0) +
                    w_bp * vec3(0.5, 0.5, 0.5), alpha);

    // outColor = vec4(1.0, 1.0, 1.0, 1.0);
}
