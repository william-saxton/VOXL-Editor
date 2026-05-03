class_name TilePickerDialog
extends AcceptDialog

## Picks a WFCTileDef from the local remote-sync cache or a file on disk.
## On confirm, emits `tile_picked` with the loaded tile resource.

signal tile_picked(tile: WFCTileDef)

const _TILE_CACHE_DIR := "user://asset_cache/voxl-tiles"

var _cached_list: ItemList
var _browse_btn: Button
var _status: Label
var _file_dialog: FileDialog
var _cached_keys: PackedStringArray = []


func _ready() -> void:
	title = "Place Tile"
	min_size = Vector2i(480, 360)
	get_ok_button().text = "Place"

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var header := Label.new()
	header.text = "Pick a tile to stamp into the editor:"
	vbox.add_child(header)

	_cached_list = ItemList.new()
	_cached_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cached_list.allow_reselect = true
	_cached_list.item_activated.connect(_on_item_activated)
	vbox.add_child(_cached_list)

	var row := HBoxContainer.new()
	_browse_btn = Button.new()
	_browse_btn.text = "Browse local file..."
	_browse_btn.pressed.connect(_on_browse_pressed)
	row.add_child(_browse_btn)

	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_status)
	vbox.add_child(row)

	add_child(vbox)

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.filters = PackedStringArray(["*.tres ; Tile Resource", "*.res ; Tile Resource"])
	_file_dialog.title = "Open Tile Resource"
	FileDialogUtil.configure_access(_file_dialog)
	_file_dialog.file_selected.connect(_on_local_file_selected)
	add_child(_file_dialog)

	confirmed.connect(_on_confirmed)


## Refresh the cached-tile list and pop up centered.
func popup_picker() -> void:
	_refresh_cached_list()
	popup_centered()


func _refresh_cached_list() -> void:
	_cached_list.clear()
	_cached_keys.clear()

	var dir := DirAccess.open(_TILE_CACHE_DIR)
	if not dir:
		_status.text = "No cached tiles. Push or pull a tile first, or browse a local file."
		return

	var entries: Array[String] = []
	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while entry_name != "":
		if not dir.current_is_dir() and not entry_name.begins_with("."):
			entries.append(entry_name)
		entry_name = dir.get_next()
	dir.list_dir_end()
	entries.sort()

	# Validate each cached file by attempting to deserialize. Truncated/corrupt
	# files (e.g. from a failed pull) are skipped so the picker doesn't fail
	# on selection.
	var skipped := 0
	for key in entries:
		var result := AssetSyncManager.tile_from_cache(key)
		if result.is_empty() or not result.get("tile"):
			skipped += 1
			continue
		_cached_list.add_item(key)
		_cached_keys.append(key)

	if _cached_keys.is_empty():
		if skipped > 0:
			_status.text = "%d cached file(s) failed to load. Push or pull a tile, or browse a local file." % skipped
		else:
			_status.text = "No cached tiles. Push or pull a tile first, or browse a local file."
	elif skipped > 0:
		_status.text = "%d cached tile(s)  (%d skipped — corrupt)" % [_cached_keys.size(), skipped]
	else:
		_status.text = "%d cached tile(s)" % _cached_keys.size()


func _on_item_activated(_idx: int) -> void:
	# Double-click confirms.
	_on_confirmed()


func _on_confirmed() -> void:
	var sel := _cached_list.get_selected_items()
	if sel.is_empty():
		_status.text = "Select a tile or use Browse."
		# Re-show because AcceptDialog auto-hides on confirm.
		call_deferred("popup_centered")
		return
	var key := _cached_keys[sel[0]]
	var result := AssetSyncManager.tile_from_cache(key)
	var tile: WFCTileDef = result.get("tile") if result else null
	if not tile:
		_status.text = "Failed to load cached tile: %s" % key
		call_deferred("popup_centered")
		return
	tile_picked.emit(tile)


func _on_browse_pressed() -> void:
	_file_dialog.popup_centered(Vector2i(700, 500))


func _on_local_file_selected(path: String) -> void:
	var res := ResourceLoader.load(path)
	if res is WFCTileDef:
		tile_picked.emit(res)
		hide()
	else:
		_status.text = "Not a WFCTileDef: %s" % path.get_file()
