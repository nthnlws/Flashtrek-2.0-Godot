import os

# Define the directory and search terms
directory = r"C:\Users\nthnl\Downloads\Oath Keepers\Oath Keepers.sbd"
search_terms = ["Michael Lewis", "mchllws", "mklws@"]

def search_files(directory, search_terms):
    lower_search_terms = [term.lower() for term in search_terms]  # Convert search terms to lowercase
    for root, _, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    lines = f.readlines()
                    for line_number, line in enumerate(lines, start=1):
                        if any(term in line.lower() for term in lower_search_terms):  # Compare with lowercase line
                            print(f"Match found in file: {file_path}")
                            print(f"Line {line_number}: {line.strip()}")
                            print("-" * 40)
            except Exception as e:
                print(f"Could not read file {file_path}: {e}")


# Run the search
search_files(directory, search_terms)
