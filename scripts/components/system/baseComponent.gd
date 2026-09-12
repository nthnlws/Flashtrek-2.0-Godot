@abstract
extends Node2D
class_name BaseComponent

signal component_completed

@abstract func mark_completed() -> void
@abstract func initialize(component_data: BaseComponentData) -> void
