import os

# Set the target directory and output file
source_dir = os.path.expanduser("~/Desktop/SwiftUI/EL-beta/")
output_file = "output.txt"

def collect_swift_files():
    # Create a list to store file information
    swift_files = []
    
    # Walk the directory and its subdirectories
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if file.endswith('.swift'):
                # Get the full path
                full_path = os.path.join(root, file)
                # Compute the relative path
                rel_path = os.path.relpath(full_path, source_dir)
                
                try:
                    # Read the file content
                    with open(full_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    # Add the relative path and content to the list
                    swift_files.append((rel_path, content))
                except Exception as e:
                    print(f"Error reading {rel_path}: {e}")

    # Write the output file
    with open(output_file, 'w', encoding='utf-8') as f:
        for rel_path, content in swift_files:
            f.write(f"File: {rel_path}\n")
            f.write("=" * 80 + "\n")
            f.write(content)
            f.write("\n" + "=" * 80 + "\n\n")

    print(f"Found and processed {len(swift_files)} Swift files")

if __name__ == "__main__":
    collect_swift_files()