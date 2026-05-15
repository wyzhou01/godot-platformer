extends PointLight2D

# 1267年波兰战场专属色调 (方案一：余烬荒原)
const COLOR_BRIGHT = Color("#ff7d32") # 核心明火色
const COLOR_DIM = Color("#a54b1e")    # 边缘暗火色

# 摇曳参数
@export var base_energy = 1.2       # 基础亮度
@export var flicker_range = 0.1   # 亮度波动范围
@export var position_shiver = 0    # 位置微颤（像素）
@export var flicker_speed = 0   # 摇曳频率

var _timer = 0.0

func _ready():
	# 初始化颜色和纹理设置
	color = COLOR_BRIGHT
	# 确保混合模式不会烧掉背景细节
	blend_mode = PointLight2D.BLEND_MODE_ADD 
	print("Kuzo 的灯火已点燃，利刃准备就绪...awa")

func _process(delta):
	_timer += delta
	if _timer >= flicker_speed:
		# 1. 核心摇曳逻辑：亮度波动
		var noise = randf_range(-flicker_range, flicker_range)
		energy = base_energy + noise
		
		# 2. 颜色插值：亮度越低，颜色越偏向暗红余烬
		# 让光圈不再“平庸”，具备真实的燃烧感
		var color_factor = (energy - (base_energy - flicker_range)) / (flicker_range * 2)
		color = COLOR_DIM.lerp(COLOR_BRIGHT, clamp(color_factor, 0.0, 1.0))
		
		# 3. 位置微颤：模拟冷风吹动火苗
		offset = Vector2(
			randf_range(-position_shiver, position_shiver),
			randf_range(-position_shiver, position_shiver)
		)
		
		# 4. 随机化节奏：打破 AI 的机械感
		_timer = 0.0
		flicker_speed = randf_range(0.05, 0.12)
