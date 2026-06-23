extends StaticBody2D

@onready var torch = $Torch
@onready var torch_light = $Torch/TorchLight
@onready var torch_particles = $Torch/TorchParticles
@onready var torch_audio = $Torch/AudioStreamPlayer2D

func setup_torch(is_on_top: bool):
	torch.visible = true
	if torch_audio:
		torch_audio.play() # Som apenas se houver tocha
		
	# Tocha sempre embaixo do pilar (Sul)
	torch.position = Vector2(0, -45)
	torch.z_index = 13
	
	# Adiciona uma segunda luz abaixo do pilar (Sul) para espelhar a luz de cima (Norte)
	var bottom_light = PointLight2D.new()
	bottom_light.texture = torch_light.texture
	bottom_light.color = torch_light.color
	bottom_light.energy = torch_light.energy
	bottom_light.shadow_enabled = torch_light.shadow_enabled
	bottom_light.shadow_filter = torch_light.shadow_filter
	bottom_light.shadow_filter_smooth = torch_light.shadow_filter_smooth
	bottom_light.texture_scale = torch_light.texture_scale
	bottom_light.blend_mode = torch_light.blend_mode
	add_child(bottom_light)
	bottom_light.position = Vector2(0, 45)
	
	# Adiciona uma terceira luz exatamente na tocha (-45) para iluminar apenas o pilar
	var pillar_light = PointLight2D.new()
	pillar_light.texture = torch_light.texture
	pillar_light.color = torch_light.color
	pillar_light.energy = torch_light.energy
	pillar_light.texture_scale = torch_light.texture_scale
	pillar_light.blend_mode = torch_light.blend_mode
	add_child(pillar_light)
	pillar_light.position = Vector2(0, -45)
	pillar_light.shadow_enabled = false
	pillar_light.range_item_cull_mask = 2 # Layer 2
	
	# Faz o Sprite2D do pilar reagir APENAS à Layer 2 (luz exclusiva) para não receber sombras das outras luzes
	$Sprite2D.light_mask = 2
	
	# Partículas nascem exatamente na posição da tocha
	torch_particles.position = Vector2.ZERO

func _ready():
	# Garante que o som comece desligado (será ligado no setup_torch se necessário)
	if torch_audio:
		torch_audio.stop()
		
	# Força a luz da tocha a ser circular e suave
	# Aumentamos o tamanho da textura para 256 para evitar cortes nas bordas
	var grad = Gradient.new()
	grad.offsets = [0.0, 0.7] # Termina de sumir no ponto 0.7 (longe da borda 1.0)
	grad.colors = [Color(1, 0.6, 0.2, 1), Color(1, 0.6, 0.2, 0)]
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.9, 0.9) # Puxamos o fim do raio para dentro
	tex.width = 256
	tex.height = 256
	
	torch_light.texture = tex
	torch_light.shadow_enabled = true
	torch_light.shadow_filter = 1
	torch_light.shadow_filter_smooth = 2.0
