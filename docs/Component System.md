
# 🛸 Technical Manual: Component System

## 1. Overview

The component system is split into two categories:

1.  **System Components**: Attached to the root of a solar system (e.g., combat encounters, escort missions).
    
2.  **Planet Components**: Attached to specific planets (e.g., scanning sequences, landing parties).
    

Both follow a **Data-Driven Pattern**:  
MissionManager modifies a `Resource`  →   `Spawner` reads the `Resource`  →  `Spawner` instantiates the Scene.

----------

## 2. The Lifecycle of a Component

### Phase A: Registration (Data)

1.  A mission is generated.
    
2.  The MissionManager identifies the target SystemData or PlanetData.
    
3.  The manager calls add_component(TYPE). This adds the enum value to the active_components array inside the Resource.
    

### Phase B: Spawning (Initialization)

1.  The player enters a system or a planet is instantiated.
    
2.  The ComponentSpawner (on the Level) or PlanetComponentSpawner (on the Planet) calls sync_components().
    
3.  The spawner iterates through the active_components array, looks up the PackedScene in the component_map, and instantiates it.
    
4.  **Crucial Step**: The spawner calls `initialize_component(data)`. This is where the component configures its difficulty, faction, or positions based on the system state.
    

### Phase C: Execution & Cleanup

1.  The component performs its logic (e.g., AnalyzePlanetComponent runs a tweened orbit).
    
2.  Once the objective is met, the component calls MissionManager.complete_mission().
    
3.  The component emits the cleanup_self signal.
    
4.  The parent spawner receives the signal and calls queue_free(), removing the component from the tree.
    

----------

## 3. Pipeline: Adding a New Component

To add a new functionality, follow these steps:

### Step 1: Define the Enum

Open SystemData.gd (for systems) or PlanetData.gd (for planets) and add your new type to the enum:

code Gdscript

```swift
enum SystemComponentTypes { KILL_FACTION, ESCORT, CONTAINER, BOUNTY_HUNTER }
```

### Step 2: Create the Scene

1.  Create a new scene inheriting from Node (or Node2D if it needs a position).
    
2.  Attach a script extending SystemComponent or PlanetComponent.
    
3.  Implement `initialize_component(Planet/SystemData)` to set up your logic.
    
4.  Save the scene in scenes/components/.
    

### Step 3: Register the Map

In the Inspector for SystemData.gd or PlanetData.gd, add your new scene to the component_map:

```swift
@export var component_map: Dictionary = {
    SystemComponentTypes.BOUNTY_HUNTER: preload("res://scenes/components/bounty_hunter_component.tscn")
}
```

### Step 4: Trigger the Component

In MissionManager.gd, update the accept_pending_mission() function to recognize your new mission type and call add_component():

code Gdscript

```swift
elif active_mission.type == MissionData.MISSION_TYPE.BOUNTY:
    system_data.add_component(SystemData.SystemComponentTypes.BOUNTY_HUNTER)
```

----------

## 4. Class Reference

### SystemComponent (Base)

-   **Purpose**: Global system logic.
    
-   **Key Function**: initialize_component(system_data: SystemData)
    
-   **Signal**: cleanup_self(component) — Must be emitted to trigger removal.
    

### PlanetComponent (Base)

-   **Purpose**: Logic tied to a Planet node.
    
-   **Property**: parent_planet — Reference to the physical planet object.
    
-   **Signal**: cleanup_self(component)
    

### ComponentSpawner

-   **Location**: Child of the main Level or planet node.
    
-   **Responsibility**: Managing the attached_components array and ensuring cleanup_system_components() is called when leaving a system to prevent memory leaks or ghost missions.
    

----------

## 5. Best Practices

-   **Static Typing**: Always use as SystemComponent or explicit types when instantiating to catch errors early.
    
-   **Cleanup**: Components are responsible for cleaning up any objects they spawn (like mission ships) in their cleanup_component() method before freeing themselves.
    
-   **SignalBus**: Use the SignalBus for game-wide events (like missionCharacterDied) rather than direct references to the Player or Level.
