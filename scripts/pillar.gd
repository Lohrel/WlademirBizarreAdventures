extends StaticBody2D

@onready var torch = $Torch
@onready var torch_light = $Torch/TorchLight
@onready var torch_particles = $Torch/TorchParticles

func setup_torch(is_on_top: bool):
	torch.visible = true
	if is_on_top:
		# Tocha embaixo do pilar (Sul)
		torch.position = Vector2(0, 18)
		torch_particles.position = Vector2(0, 5) # Faíscas nascem abaixo da tocha
	else:
		# Tocha em cima do pilar (Norte)
		torch.position = Vector2(0, -18)
		torch_particles.position = Vector2(0, -5) # Faíscas nascem acima da tocha

func _ready():
	# Força a luz da tocha a ser circular e suave (usando a mesma lógica dos vagalumes)
	var grad = Gradient.new()
	grad.offsets = [0.0, 0.8]
	grad.colors = [Color(1,1,1,1), Color(1,1,1,0)]
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 128
	tex.height = 128
	
	torch_light.texture = tex
	# Ativa as sombras para a luz respeitar paredes e pilastras
	torch_light.shadow_enabled = true
	torch_light.shadow_filter = 1
	torch_light.shadow_filter_smooth = 2.0
