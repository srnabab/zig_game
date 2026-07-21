import mitsuba as mi
import drjit as dr
import numpy as np
import struct

# 1. 设置 Mitsuba 3 变体（CPU 向量化执行模式）
mi.set_variant('llvm_ad_rgb')

# 2. 定义离散化尺寸与步长
M_EFF_STEPS = 64
SIGMA_STEPS = 8

THETA_RES = 128  # 仰角 Theta 的离散网格分辨率
PHI_RES = 256    # 方位角 Phi 的离散网格分辨率

U1_STEPS = 128   # 运行时输入随机数 u1 的采样点数
U2_STEPS = 128   # 运行时输入随机数 u2 的采样点数

# 3. 显式建立 u1, u2 在 [0, 1] 范围内的均匀网格
u1_grid = np.zeros((U1_STEPS, U2_STEPS), dtype=np.float32)
u2_grid = np.zeros((U1_STEPS, U2_STEPS), dtype=np.float32)
for i in range(U1_STEPS):
    for j in range(U2_STEPS):
        u1_grid[i, j] = i / (U1_STEPS - 1)
        u2_grid[i, j] = j / (U2_STEPS - 1)

# 将网格展平并包装为 Mitsuba 的连续 2D 采样点类型
u1_flat = u1_grid.flatten()
u2_flat = u2_grid.flatten()
u_samples = mi.Point2f(u2_flat, u1_flat)

# 4. 根据实际公式更新的 2D PDF 计算函数
def compute_pdf_grid(m_eff, sigma):
    theta_edges = np.linspace(0.0, np.pi/2.0, THETA_RES)
    phi_edges = np.linspace(0.0, 2.0 * np.pi, PHI_RES)
    
    # 建立 2D 离散坐标网格 (i, j)
    theta, phi = np.meshgrid(theta_edges, phi_edges, indexing='ij')
    
    # 进行安全截断，防止除零错误
    m_eff_safe = max(m_eff, 1e-4)
    sigma_safe = max(sigma, 1e-4)
    
    # 计算点积项
    sin_theta = np.sin(theta)
    cos_theta = np.cos(theta)
    sin_phi = np.sin(phi)
    cos_phi = np.cos(phi)
    
    dot_x = sin_theta * cos_phi  # \hat{x} \cdot \omega_h
    dot_y = sin_theta * sin_phi  # \hat{y} \cdot \omega_h
    
    # 计算 D'(m_eff, x)
    m2 = m_eff_safe ** 2
    denom = m2 + (1.0 - m2) * (dot_x ** 2)
    D_prime = m2 / (np.pi * (denom ** 2))
    
    # 计算 D(m_eff, sigma; \omega_h)
    sigma2 = sigma_safe ** 2
    exponent = - (dot_y ** 2) / sigma2
    D = D_prime * np.exp(exponent)
    
    # 对应步骤 2：P_ij = D * cos_theta * sin_theta
    pdf = D * cos_theta * sin_theta
    
    return pdf

# 5. 主循环烘焙并写入二进制文件
output_filename = "microfacet_sample_lut.bin"

print(f"开始使用实际公式烘焙 LUT，写入文件: {output_filename}")
with open(output_filename, "wb") as f:
    for m_idx in range(M_EFF_STEPS):
        # 将 m_eff 映射到 [0, 1] 范围
        m_eff = m_idx / (M_EFF_STEPS - 1) if M_EFF_STEPS > 1 else 0.0
        
        for s_idx in range(SIGMA_STEPS):
            # 将 sigma 映射到 [0, 1] 范围
            sigma = s_idx / (SIGMA_STEPS - 1) if SIGMA_STEPS > 1 else 0.0
            
            # 计算离散 PDF 网格
            pdf = compute_pdf_grid(m_eff, sigma)
            
            # 包装为 Mitsuba 3 兼容的 TensorXf
            pdf_f32 =  pdf.astype(np.float32)
            
            # 自动生成对应的 1D 边缘与 1D 条件 CDF 结构
            dist = mi.DiscreteDistribution2D(pdf_f32)
            
            # 并行数值求逆解出对应的 (x, y) 的归一化坐标值
            sampled_pos, _, _ = dist.sample(u_samples)
            
            y_coords = np.array(sampled_pos.y) # 对应仰角（归一化）
            x_coords = np.array(sampled_pos.x) # 对应方位角（归一化）
            
            # 重新映射至物理弧度区间：\theta ∈ [0, \pi/2], \phi ∈ [0, 2\pi]
            theta_radians = y_coords * (np.pi / 2.0)
            phi_radians = x_coords * (2.0 * np.pi)
            
            # 顺序打包为两个 float 连续写入
            for t, p in zip(theta_radians, phi_radians):
                f.write(struct.pack('ff', float(t), float(p)))

print("烘焙完成！")
