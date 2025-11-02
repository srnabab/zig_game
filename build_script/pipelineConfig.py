import json
import sys
import os

def generate_pipeline_config(pipeline_name):
    """
    Generates a dictionary containing the default configuration for a
    standard opaque graphics pipeline.
    """
    
    # Generate default shader names based on the pipeline name (e.g., "PBR_Opaque" -> "pbr_opaque")
    shader_basename = pipeline_name.lower()
    
    config = {
      "Name": pipeline_name,
      "PipelineType": "Graphics",
      "Shaders": [
        f"{shader_basename}.vert.spv", f"{shader_basename}.frag.spv"
      ],
      "VersionCount": 0,
      "VertexInput": {
        "bindings": [
          # Example for a vertex with Position, Normal, and UV
          { "binding": 0, "stride": 32, "inputRate": "VERTEX", }, 
        ],
        "attributes": [
          # Corresponds to: layout(location = 0) in vec3 inPosition;
          { "location": 0, "binding": 0, "format": "R32G32B32_SFLOAT", "offset": 0 },
          # Corresponds to: layout(location = 1) in vec3 inNormal;
          { "location": 1, "binding": 0, "format": "R32G32B32_SFLOAT", "offset": 12 },
          # Corresponds to: layout(location = 2) in vec2 inUV;
          { "location": 2, "binding": 0, "format": "R32G32_SFLOAT", "offset": 24 },
        ]
      },
      "InputState": {
        "InputStatepNext": None,
        "flag": 0,
          "vertexBindingDescriptionCount": 1,
          "vertexAttributeDescriptionCount": 3
      },
      "InputAssembly": {
        "InputAssemblypNext": None,
        "flag": 0,
        "topology": "TRIANGLE_LIST",
        "primitiveRestartEnable": False
      },
      "TessellationState": {
        "TessellationStatepNext": None,
        "flag": 0,
          "patchControlPoints": 0,
      },
      "ViewportState": {
        "ViewportStatepNext": None,
        "flag": 0,
        "viewports": [{"x": 0.0,"y": 0.0, "width": 800,"height":600,"minDepth":0.0,"maxDepth":1.0}],
        "scissors": [{"offset": {"x": 0,"y":0}, "extent": {"width":800,"height":600}}] 
      },
      "RasterizationState": {
        "RasterizationStatepNext": None,
        "flag": 0,
        "depthClampEnable": False,
        "rasterizerDiscardEnable": False,
        "polygonMode": "FILL",
        "cullMode": "BACK_BIT",
        "frontFace": "COUNTER_CLOCKWISE",
        "depthBiasEnable": False,
        "depthBiasConstantFactor": 0.0,
        "depthBiasClamp": 0.0,
        "depthBiasSlopeFactor": 0.0,
        "lineWidth": 1.0,
      },
      "MultisampleState": {
        "MultisampleStatepNext": None,
        "flag": 0,
        "rasterizationSamples": "1_BIT",
        "sampleShadingEnable": False,
        "minSampleShading": 1.0,
        "alphaToCoverageEnable": False,
        "alphaToOneEnable": False,
      },
      "DepthStencilState": {
        "DepthStencilStatepNext": None,
        "flag": 0,
        "depthTestEnable": True,
        "depthWriteEnable": True,
        "depthCompareOp": "LESS",
        "depthBoundsTestEnable": False,
        "stencilTestEnable": False,
        "front": {
            "failOp": "KEEP",
            "passOp": "KEEP",
            "depthFailOp": "KEEP",
            "compareOp": "NEVER",
            "compareMask": 0,
            "writeMask": 0,
            "reference": 0,
        },
        "back": None,
        "minDepthBounds": 0.0,
        "maxDepthBounds": 1.0,
      },
      "ColorBlendState": {
        "ColorBlendStatepNext": None,
        "flag": 0,
        "logicOpEnable": False,
        "logicOp": "COPY",
        "attachments": [
          {
            "blendEnable": False,
            "srcColorBlendFactor": "ONE",
            "dstColorBlendFactor": "ZERO",
            "colorBlendOp": "ADD",
            "srcAlphaBlendFactor": "ONE",
            "dstAlphaBlendFactor": "ZERO",
            "alphaBlendOp": "ADD",
            "colorWriteMask": ["R", "G", "B", "A"]
          }
        ],
        "blendConstants": [0.0, 0.0, 0.0, 0.0],
      },
      "DynamicStates": {
        "DynamicStatespNext": None,
        "flag": 0,
         "States": [
        "VIEWPORT",
        "SCISSOR",
      ]
      },
      "PipelineRendering": {
          "color": ["R8G8B8A8_SRGB"],
          "depth": "D32_SFLOAT",
          "stencil": "UNDEFINED"
      }
    }
    
    return config

def main():
    """ Main execution function """
    if len(sys.argv) < 2:
        print(f"Usage: python {sys.argv[0]} <PipelineName> (output)")
        print("Example: python create_pipeline_config.py PBR_Opaque_StaticMesh")
        sys.exit(1)
        
    pipeline_name = sys.argv[1]


    output_filename = f"{pipeline_name}.pipe"
    if len(sys.argv) > 2:
      output_filename = sys.argv[2]
    
    if os.path.exists(output_filename):
        print(f"Error: File '{output_filename}' already exists.")
        sys.exit(1)
        
    print(f"Generating pipeline configuration for '{pipeline_name}'...")
    
    config_data = generate_pipeline_config(pipeline_name)
    
    try:
        with open(output_filename, 'w') as f:
            # Use indent=2 for pretty-printing the JSON
            json.dump(config_data, f, indent=2)
        print(f"Successfully created '{output_filename}'!")
    except IOError as e:
        print(f"Error writing to file: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
