extends StaticBody2D

@onready var torch = $Torch
@onready var torch_light = $Torch/TorchLight
@onready var torch_particles = $Torch/TorchParticles

func setup_torch(is_on_top: bool):
	torch.visible = true
	if is_on_top:
		# Tocha embaixo do pilar (Sul)
		torch.position = Vector2(0, 18)
	else:
		# Tocha em cima do pilar (Norte)
		torch.position = Vector2(0, -18)
	
	# Partículas nascem exatamente na posição da tocha
	torch_particles.position = Vector2.ZERO

func _ready():
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
