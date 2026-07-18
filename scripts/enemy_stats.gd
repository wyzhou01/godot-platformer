class_name EnemyStats extends Resource

## 敌人数值配置 - 替代散落的 @export 变量
## 用法: 在 enemy .tscn 里 Inspector 选 Load Resource → enemy_stats.tres

@export var health: int = 9
@export var speed: float = 50.0
@export var damage_amount: float = 1.0
@export var detection_range: float = 800.0
@export var attack_range: float = 80.0
@export var attack_cooldown: float = 1.0
@export var block_chance: float = 0.0  # 0 = 不格挡
@export var arrow_speed: float = 600.0
@export var arrow_range: float = 1800.0
@export var is_archer: bool = false
