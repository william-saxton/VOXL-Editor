class_name SunDialog
extends AcceptDialog

## Sun controls dialog: toggle the editor's directional light on/off and adjust
## its azimuth (compass heading), elevation (height above horizon), and energy
## to simulate different times of day.

signal sun_changed(enabled: bool, azimuth_deg: float, elevation_deg: float, energy: float)

const DEFAULT_AZIMUTH := 45.0
const DEFAULT_ELEVATION := 55.0
const DEFAULT_ENERGY := 1.0

var _enabled_check: CheckBox
var _azimuth_slider: HSlider
var _elevation_slider: HSlider
var _energy_slider: HSlider

var _enabled: bool = true
var _azimuth_deg: float = DEFAULT_AZIMUTH
var _elevation_deg: float = DEFAULT_ELEVATION
var _energy: float = DEFAULT_ENERGY


func _ready() -> void:
	title = "Sun"
	min_size = Vector2i(360, 0)
	# Use OK as a "Close" — changes apply live via sliders.
	get_ok_button().text = "Close"

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	_enabled_check = CheckBox.new()
	_enabled_check.text = "Sun Enabled"
	_enabled_check.button_pressed = _enabled
	_enabled_check.toggled.connect(_on_enabled_toggled)
	vbox.add_child(_enabled_check)

	vbox.add_child(HSeparator.new())

	_azimuth_slider = _add_slider(vbox, "Azimuth", 0.0, 360.0, 1.0, _azimuth_deg, "%.0f°")
	_azimuth_slider.value_changed.connect(_on_azimuth_changed)

	_elevation_slider = _add_slider(vbox, "Elevation", -10.0, 90.0, 1.0, _elevation_deg, "%.0f°")
	_elevation_slider.value_changed.connect(_on_elevation_changed)

	_energy_slider = _add_slider(vbox, "Energy", 0.0, 2.0, 0.05, _energy, "%.2fx")
	_energy_slider.value_changed.connect(_on_energy_changed)

	vbox.add_child(HSeparator.new())

	var reset_btn := Button.new()
	reset_btn.text = "Reset to defaults"
	reset_btn.pressed.connect(_on_reset_pressed)
	vbox.add_child(reset_btn)

	add_child(vbox)


## Sync the dialog's UI to externally-held state (e.g. on first open).
func sync_state(enabled: bool, azimuth_deg: float, elevation_deg: float, energy: float) -> void:
	_enabled = enabled
	_azimuth_deg = azimuth_deg
	_elevation_deg = elevation_deg
	_energy = energy
	if _enabled_check:
		_enabled_check.set_pressed_no_signal(enabled)
		_azimuth_slider.set_value_no_signal(azimuth_deg)
		_elevation_slider.set_value_no_signal(elevation_deg)
		_energy_slider.set_value_no_signal(energy)
		_refresh_labels()


func _add_slider(parent: VBoxContainer, label_text: String, min_v: float, max_v: float,
		step: float, value: float, fmt: String) -> HSlider:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "%s: %s" % [label_text, fmt % value]
	lbl.custom_minimum_size.x = 130
	lbl.set_meta("label_text", label_text)
	lbl.set_meta("fmt", fmt)
	row.add_child(lbl)
	parent.add_child(row)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(slider)
	# Stash the label on the slider so refresh can find it.
	slider.set_meta("label", lbl)
	return slider


func _refresh_label(slider: HSlider) -> void:
	var lbl: Label = slider.get_meta("label")
	if not lbl:
		return
	var label_text: String = lbl.get_meta("label_text")
	var fmt: String = lbl.get_meta("fmt")
	lbl.text = "%s: %s" % [label_text, fmt % slider.value]


func _refresh_labels() -> void:
	_refresh_label(_azimuth_slider)
	_refresh_label(_elevation_slider)
	_refresh_label(_energy_slider)


func _on_enabled_toggled(pressed: bool) -> void:
	_enabled = pressed
	_emit()


func _on_azimuth_changed(value: float) -> void:
	_azimuth_deg = value
	_refresh_label(_azimuth_slider)
	_emit()


func _on_elevation_changed(value: float) -> void:
	_elevation_deg = value
	_refresh_label(_elevation_slider)
	_emit()


func _on_energy_changed(value: float) -> void:
	_energy = value
	_refresh_label(_energy_slider)
	_emit()


func _on_reset_pressed() -> void:
	sync_state(true, DEFAULT_AZIMUTH, DEFAULT_ELEVATION, DEFAULT_ENERGY)
	_emit()


func _emit() -> void:
	sun_changed.emit(_enabled, _azimuth_deg, _elevation_deg, _energy)
