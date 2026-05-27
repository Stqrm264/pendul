extends ColorRect


var zoom: float = 1.0
var offset: Vector2 = Vector2.ZERO
var is_panning: bool = false

func _ready() -> void:
    update_shader_navigation()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            var old_zoom: float = zoom
            zoom /= 1.1
            var uv_mouse: Vector2 = event.position / size
            var centered_uv_mouse: Vector2 = uv_mouse - Vector2(0.5, 0.5)
            offset += centered_uv_mouse * (old_zoom - zoom)
            update_shader_navigation()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            var old_zoom: float = zoom
            zoom *= 1.1
            var uv_mouse: Vector2 = event.position / size
            var centered_uv_mouse: Vector2 = uv_mouse - Vector2(0.5, 0.5)
            offset += centered_uv_mouse * (old_zoom - zoom)
            update_shader_navigation()
            
        elif event.button_index == MOUSE_BUTTON_LEFT:
            is_panning = event.pressed

    elif event is InputEventMouseMotion and is_panning:
        var uv_movement: Vector2 = event.relative / size
        
        # Multiply by zoom to keep panning aligned with the cursor at any zoom level.
        # Subtract the movement because moving the mouse right means the camera moves left over the texture.
        offset -= uv_movement * zoom 
        update_shader_navigation()

# Send updated parameters to the shader
func update_shader_navigation() -> void:
    material.set_shader_parameter("zoom", zoom)
    material.set_shader_parameter("offset", offset)

    update_axes()

@onready var x_min: Label = %XMin
@onready var x_max: Label = %XMax
@onready var y_min: Label = %YMin
@onready var y_max: Label = %YMax

func update_axes() -> void:
    var theta1min_deg: float = (-0.5 * zoom + offset.x) * 360
    var theta1max_deg: float = ( 0.5 * zoom + offset.x) * 360
    var theta2min_deg: float = (-0.5 * zoom + offset.y) * 360
    var theta2max_deg: float = ( 0.5 * zoom + offset.y) * 360
    
    theta1min_deg = snappedf(theta1min_deg, 0.1)
    theta1max_deg = snappedf(theta1max_deg, 0.1)
    theta2min_deg = snappedf(theta2min_deg, 0.1)
    theta2max_deg = snappedf(theta2max_deg, 0.1)

    x_min.text = "Theta\n= " + str(theta1min_deg)
    x_max.text = "Theta\n= " + str(theta1max_deg)
    y_min.text = "Theta\n= " + str(theta2min_deg)
    y_max.text = "Theta\n= " + str(theta2max_deg)
