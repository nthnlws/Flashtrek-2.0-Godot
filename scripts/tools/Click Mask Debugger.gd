extends TextureButton

func _draw():
	if texture_click_mask:
		# Get mask size
		var mask_size = texture_click_mask.get_size()
		# Loop through mask pixels
		for y in range(mask_size.y):
			for x in range(mask_size.x):
				if texture_click_mask.get_bit(x, y):
					# Draw a semi-transparent red pixel where clickable
					draw_rect(Rect2(x, y, 1, 1), Color(1, 0, 0, 0.4))
