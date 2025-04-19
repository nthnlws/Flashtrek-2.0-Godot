# Original dictionary keys
ship_sprites_keys = [
    "Merchantman", "Keldon-Class", "batlh-Class", "Jem'Hadar", "sech-Class", "Pathfinder-Class",
    "Steamrunner-Class", "Soyuz-Class", "Miranda-Class", "Nimitz-Class", "Freedom-Class", "Intrepid-Class",
    "Niagara-Class", "Talarian Freighter", "Galor-Class", "Bajoran Freighter", "daSpu'-Class",
    "Klingon Bird-of-Prey (Discovery era)", "Walker-Class", "Sovereign-Class", "Malachowski-Class",
    "Miranda-Class (Lantree variant)", "Nova-Class", "Constitution-Class (Strange New Worlds)",
    "Nova-Class (Rhode Island variant)", "New Orleans-Class", "D'Kora Marauder", "Hideki-Class",
    "Qugh-Class", "Hiawatha-Class", "Mars Synth Defense Ship", "Intrepid-Class Aeroshuttle", "Gagarin-Class",
    "Saber-Class", "Miranda-Class (Saratoga variant)", "Parliament-Class", "Georgiou-Class", "Defiant-Class",
    "Cheyenne-Class", "Peregrine-Class", "Odyssey-Class", "D5-Class", "Risian Corvette", "Breen Interceptor",
    "Bajoran Interceptor", "Oberth-Class", "Cardenas-Class", "Vesta-Class", "Miranda-Class (Antares variant)",
    "Challenger-Class", "Constitution-II-Class", "Constitution-III-Class", "Galaxy-Class", "Maquis Raider",
    "chargh-Class", "Wallenberg-Class", "Dhailkhina-Class", "Sampson-Class", "Excelsior-Class",
    "Class III Neutronic Fuel Carrier (Kobayashi Maru)", "Shepard-Class", "Norway-Class", "California-Class",
    "Galaxy-Class (Venture variant)", "Springfield-Class", "Theta-Class", "Groumall Freighter",
    "Tellarite Cruiser", "Magee-Class", "bortaS bIr-Class", "Dia Vectau-Class", "Hernandez-Class",
    "Excelsior-Class Refit", "Luna-Class", "Edison-Class", "Constellation-Class", "Sagan-Class",
    "Sutherland-Class", "Nebula-Class (Phoenix variant)", "La Sirena", "Hysperian Monaveen",
    "Risian Luxury Cruiser", "B'rel-Class", "D'deridex-Class", "Engle-Class", "Reliant-Class", "Ross-Class",
    "Akira-Class", "Ambassador-Class", "Excelsior-II-Class", "Hoover-Class", "Nebula-Class"
]

# Convert to enum format
enum_format = "enum SHIP_SPRITES {\n"
for key in ship_sprites_keys:
    # Replace spaces and special characters with underscores
    enum_name = key.replace(" ", "_").replace("-", "_").replace("'", "").replace("(", "").replace(")", "")
    enum_format += f"    {enum_name},\n"
enum_format += "}"

print(enum_format)