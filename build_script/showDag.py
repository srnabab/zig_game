import sys
import os
from graphviz import Source

# 检查是否输入了路径
if len(sys.argv) < 2:
    print("错误: 请提供 .dot 文件的路径")
    print("用法: python render_script.py your_file.dot")
    sys.exit(1)

# 从命令行第一个参数获取路径
path = sys.argv[1]

if os.path.exists(path):
    # 建议指定编码，防止中文乱码
    s = Source.from_file(path, encoding='utf-8')
    # 自动根据输入的文件名生成输出文件名（去掉.dot后缀）
    output_name = os.path.splitext(path)[0]
    s.render(output_name, format='png', view=True)
    print(f"成功渲染: {output_name}.png")
else:
    print(f"错误: 找不到文件 '{path}'")
