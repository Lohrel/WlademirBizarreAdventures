import re

content = open('scenes/pillar.tscn', 'r').read()

# Remove z_index = 2
content = re.sub(r'z_index = 2\n', '', content)

# Enable y_sort_enabled on the root node
content = re.sub(r'(\[node name="Pillar" type="StaticBody2D".*?\])', r'\1\ny_sort_enabled = true', content)

# Enable y_sort_enabled on the sprite
content = re.sub(r'(\[node name="Sprite2D" type="Sprite2D" parent="\.".*?\])', r'\1\ny_sort_enabled = true', content)

with open('scenes/pillar.tscn', 'w') as f:
    f.write(content)
