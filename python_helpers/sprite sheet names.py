# Parameters for the sprite sheet
sprite_width = 48   # Width of each sprite
sprite_height = 48  # Height of each sprite
tall_sprite_height = 96  # Height for taller sprites

# List of ship names in a 13x7 grid with note for tall sprites
ship_names_grid = [
    ["Merchantman", "Keldon-Class", "batlh-Class", "Jem'Hadar Attack Ship", "sech-Class", "blank", "Pathfinder-Class",
     "Steamrunner-Class", "Soyuz-Class", "Miranda-Class", "Nimitz-Class", "Freedom-Class", "Intrepid-Class", "Niagara-Class"],
    ["Talarian Freighter", "Galor-Class", "Bajoran Freighter", "daSpu'-Class", "Klingon Bird-of-Prey (Discovery era)", "blank",
     "Walker-Class", "Sovereign-Class", "Malachowski-Class", "Miranda-Class (Lantree variant)", "Nova-Class",
     "Constitution-Class (Strange New Worlds)", "Nova-Class (Rhode Island variant)", "New Orleans-Class"],
    ["D'Kora Marauder", "Hideki-Class", "Qugh-Class", "Hiawatha-Class", "Mars Synth Defense Ship", "blank",
     "Intrepid-Class Aeroshuttle", "Gagarin-Class", "Saber-Class", "Miranda-Class (Saratoga variant)", "Parliament-Class",
     "Georgiou-Class", "Defiant-Class", "Cheyenne-Class"],
    ["Peregrine-Class", "Odyssey-Class", "D5-Class (Tanker variant)", "Risian Corvette", "Breen Interceptor",
     "Bajoran Interceptor", "Oberth-Class", "Cardenas-Class", "Vesta-Class", "Miranda-Class (Antares variant)",
     "Challenger-Class", "Constitution-II-Class", "Constitution-III-Class", "Galaxy-Class"],
    ["Maquis Raider", "Odyssey-Class", "chargh-Class", "Wallenberg-Class", "blank", "Dhailkhina-Class", "Sampson-Class", "Excelsior-Class",
     "Class III Neutronic Fuel Carrier (Kobayashi Maru)", "Shepard-Class", "Norway-Class", "California-Class",
     "Galaxy-Class (Venture variant)", "Springfield-Class"],
    ["Theta-Class", "Groumall Freighter", "Tellarite Cruiser", "Magee-Class", "bortaS bIr-Class", "Dia Vectau-Class",
     "Hernandez-Class", "Excelsior-Class Refit", "Luna-Class", "Edison-Class", "Constellation-Class", "Sagan-Class",
     "Sutherland-Class", "Nebula-Class (Phoenix variant)"],
    ["La Sirena", "Groumall Freighter", "Hysperian Monaveen", "Risian Luxury Cruiser", "B'rel-Class", "D'deridex-Class", "Engle-Class",
     "Reliant-Class", "Ross-Class", "Akira-Class", "Ambassador-Class", "Excelsior-II-Class", "Hoover-Class", "Nebula-Class"]
]

# Generate the dictionary
ship_sprites = {}
for row_index, row in enumerate(ship_names_grid):
    for col_index, ship_name in enumerate(row):
        if ship_name.lower() != "blank":  # Exclude blanks
            if ship_name == "Odyssey-Class" or ship_name == "Groumall Freighter":  # Tall sprites
                x = col_index * sprite_width
                y = row_index * sprite_height
                ship_sprites[ship_name] = f"Rect2({x}, {y}, {sprite_width}, {tall_sprite_height})"
            else:  # Regular sprites
                x = col_index * sprite_width
                y = row_index * sprite_height
                ship_sprites[ship_name] = f"Rect2({x}, {y}, {sprite_width}, {sprite_height})"

# Format the output as a dictionary for use in Godot
formatted_output = "ship_sprites = {\n"
for name, rect in ship_sprites.items():
    formatted_output += f'    "{name}": {rect},\n'
formatted_output += "}"

print(formatted_output)