import os

def count_lines_in_gd_files(directory):
    total_lines = 0

    # Loop through all files in the specified directory
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".gd"):
                file_path = os.path.join(root, file)
                try:
                    # Open the .gd file and count the number of lines
                    with open(file_path, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                        num_lines = len(lines)
                        total_lines += num_lines
                        print(f"{file_path}: {num_lines} lines")
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")

    print(f"\nTotal number of lines in .gd files: {total_lines}")

if __name__ == "__main__":
    # Specify the folder containing the .gd files
    folder_path = r"C:\Users\nthnl\Desktop\Code\Flashtrek-2.0-Godot\scripts"
    count_lines_in_gd_files(folder_path)
