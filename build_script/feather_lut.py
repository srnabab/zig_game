import mitsuba as mi
import drjit as dr
import numpy as np
from pyktx import KtxTexture2, KtxTextureCreateInfo, KtxTextureCreateStorage, VkFormat

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

def convert_raw_to_ktx2(raw_bytes, output_ktx_path, width, height, depth=1):
    # 1. 计算纹理维度 (Dimension)
    num_dimensions = 3 if depth > 1 else 2
    
    # 2. 设定 KTX2 创建信息（存储两个 float (theta, phi)，使用 RG32_SFLOAT 格式）
    vk_format = VkFormat.VK_FORMAT_R32G32_SFLOAT 
    
    info = KtxTextureCreateInfo(
        gl_internal_format=None,          # KTX2 格式主要依赖 vk_format，此处填 None
        vk_format=vk_format,
        base_width=width,
        base_height=height,
        base_depth=depth,
        num_dimensions=num_dimensions,
        num_levels=1,                     # 默认不生成 mipmap
        num_layers=1,
        num_faces=1,
        is_array=False,
        generate_mipmaps=False
    )
    
    # 3. 创建 KTX2 纹理对象并为其在内存中分配存储空间
    texture = KtxTexture2.create(info, KtxTextureCreateStorage.ALLOC)
    
    # 4. 写入二进制数据
    if num_dimensions == 2:
        # 2D 纹理：直接写入整张图
        texture.set_image_from_memory(0, 0, 0, raw_bytes)
    else:
        # 3D 纹理：set_image_from_memory 要求按切片(Slice)逐层写入
        # 计算单个切片的字节大小 (width * height * 2 channels * 4 bytes)
        slice_size = len(raw_bytes) // depth
        for z in range(depth):
            slice_bytes = raw_bytes[z * slice_size : (z + 1) * slice_size]
            # 参数分别表示: (mipmap层级, 数组层级, 3D切片z索引, 单切片字节数据)
            texture.set_image_from_memory(0, 0, z, slice_bytes)

    # 5. 保存为 .ktx2 文件
    texture.write_to_named_file(output_ktx_path)

# 预分配用于保存所有 float 数据的 5D 数组
# 维度含义: [m_eff, sigma, u1, u2, 2(theta/phi)]
baked_data = np.zeros((M_EFF_STEPS, SIGMA_STEPS, U1_STEPS, U2_STEPS, 2), dtype=np.float32)

for m_idx in range(M_EFF_STEPS):
    # 将 m_eff 映射到 [0, 1] 范围
    m_eff = m_idx / (M_EFF_STEPS - 1) if M_EFF_STEPS > 1 else 0.0
    
    for s_idx in range(SIGMA_STEPS):
        # 将 sigma 映射到 [0, 1] 范围
        sigma = s_idx / (SIGMA_STEPS - 1) if SIGMA_STEPS > 1 else 0.0
        
        # 计算离散 PDF 网格
        pdf = compute_pdf_grid(m_eff, sigma)
        
        # 包装为 Mitsuba 3 兼容的 TensorXf
        pdf_f32 = pdf.astype(np.float32)
        
        # 自动生成对应的 1D 边缘与 1D 条件 CDF 结构
        dist = mi.DiscreteDistribution2D(pdf_f32)
        
        # 并行数值求逆解出对应的 (x, y) 的归一化坐标值
        sampled_pos, _, _ = dist.sample(u_samples)
        
        y_coords = np.array(sampled_pos.y) # 对应仰角（归一化）
        x_coords = np.array(sampled_pos.x) # 对应方位角（归一化）
        
        # 重新映射至物理弧度区间：\theta ∈ [0, \pi/2], \phi ∈ [0, 2\pi]
        theta_radians = y_coords * (np.pi / 2.0)
        phi_radians = x_coords * (2.0 * np.pi)
        
        # 写入数据矩阵中
        baked_data[m_idx, s_idx, :, :, 0] = theta_radians.reshape(U1_STEPS, U2_STEPS)
        baked_data[m_idx, s_idx, :, :, 1] = phi_radians.reshape(U1_STEPS, U2_STEPS)

# 转换为连续的 bytes 二进制流
raw_bytes = baked_data.tobytes()

# 导出为 3D KTX2 纹理:
# Width = U2_STEPS (128), Height = U1_STEPS (128), Depth = M_EFF_STEPS * SIGMA_STEPS (512)
output_file = "baked_lut.ktx2"
convert_raw_to_ktx2(
    raw_bytes=raw_bytes,
    output_ktx_path=output_file,
    width=U2_STEPS,
    height=U1_STEPS,
    depth=M_EFF_STEPS * SIGMA_STEPS
)

print(f"烘焙完成！已成功保存至: {output_file}")
