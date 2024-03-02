# Utilities for spawning and positioning particle emitters
# when a physics object collides with another object.

class_name Sparks


# Generates sparks from all detected contact points.
# Call this method from _integrate_forces, passing in the state parameter.
# An instance of "sparks" will be added to the given container.
static func emit_from_collisions(
	state: Physics2DDirectBodyState, sparks: PackedScene, container: Node
):
	for i in state.get_contact_count():
		emit_from_collision(state, i, sparks, container)


# Generates sparks from a single contact point.
# Prefer to use emit_from_collisions, unless you need to conditionally add
# sparks only for certain contact points.
static func emit_from_collision(
	state: Physics2DDirectBodyState, index: int, sparks: PackedScene, container: Node
):
	var normal = state.get_contact_local_normal(index)

	var emitter = sparks.instance()
	emitter.add_to_group("sparks")
	emitter.position = state.get_contact_collider_position(index)
	emitter.process_material.direction = Vector3(normal.x, normal.y, 0)

	container.add_child(emitter)


# Clear emitters that have finished emitting.
# This method can be called infrequently, for example using a timer.
static func garbage_collect(tree: SceneTree):
	# TODO: Is it better for performance to keep a pool of reusable emitters?
	for emitter in tree.get_nodes_in_group("sparks"):
		if not emitter.emitting:
			emitter.queue_free()
