import json
import sys
import os

def generate_pipeline_config(pipeline_name):

    config = {
        "flags": 0,
        "magFilter": 0,
        "minFilter": 0,
        "mipmapMode": 0,
        "addressModeU": 0,
        "addressModeV": 0,
        "addressModeW": 0,
        "mipLodBias": 0.0,
        "anisotropyEnable": False,
        "maxAnisotropy": 1.0,
        "compareEnable": False,
        "compareOp": 0,
        "minLod": 0.0,
        "maxLod": 0.0,
        "borderColor": 0,
        "unnormalizedCoordinates": False,
    }
    
    return config

def main():
    """ Main execution function """
    if len(sys.argv) < 2:
        print(f"Usage: python {sys.argv[0]} <SamplerName> (output)")
        sys.exit(1)
        
    pipeline_name = sys.argv[1]


    output_filename = f"{pipeline_name}.json"
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

