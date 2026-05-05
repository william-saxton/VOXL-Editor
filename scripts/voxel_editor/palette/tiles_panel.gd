class_name TilesPanel
extends VBoxContainer

## Lists tiles available in the local cache (populated by remote sync) and
## lets the user click one to enter Place Tile mode. Sits in the right-side
## tab container alongside the palette tab.

signal tile_place_requested(tile: WFCTileDef)

const _TILE_CACHE_DIR := "user://asset_cache/voxl-tiles"
const _THUMB_SIZE := Vector2i(64, 56)

var _list: ItemList
var _status: Label
var _refresh_btn: Button
var _keys: PackedStringArray = []


func _ready() -> void:
	add_theme_constant_override("separation", 4)

	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "Tiles"
	title.add_theme_font_size_override("font_size", 13)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_refresh_btn = Button.new()
	_refresh_btn.text = "Refresh"
	_refresh_btn.tooltip_text = "Re-scan local tile cache"
	_refresh_btn.pressed.connect(refresh)
	header.add_child(_refresh_btn)
	add_child(header)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.icon_mode = ItemList.ICON_MODE_TOP
	_list.fixed_icon_size = _THUMB_SIZE
	_list.max_columns = 0  # auto-flow
	_list.same_column_width = true
	_list.fixed_column_width = 96
	_list.allow_reselect = true
	_list.item_activated.connect(_on_item_activated)
	add_child(_list)

	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(0.62, 0.60, 0.64))
	_status.add_theme_font_size_override("font_size", 11)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)

	refresh()


## Re-scan the cache directory and rebuild the list.
func refresh() -> void:
	_list.clear()
	_keys.clear()

	var dir := DirAccess.open(_TILE_CACHE_DIR)
	if not dir:
		_status.text = "No cached tiles. Push a tile or configure remote sync."
		return

	var entries: Array[String] = []
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and not entry.begins_with(".") and entry.ends_with(".voxltile"):
			entries.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	entries.sort()

	var skipped := 0
	for key in entries:
		var result := AssetSyncManager.tile_from_cache(key)
		var tile: WFCTileDef = result.get("tile") if not result.is_empty() else null
		if not tile:
			skipped += 1
			continue
		var label := tile.tile_name if not tile.tile_name.strip_edges().is_empty() else key
		var idx := _list.add_item(label, _make_thumbnail(tile))
		_list.set_item_tooltip(idx, "%s\n(%s)" % [label, key])
		_keys.append(key)

	if _keys.is_empty():
		if skipped > 0:
			_status.text = "%d cached file(s) failed to load." % skipped
		else:
			_status.text = "No cached tiles. Push a tile or configure remote sync."
	elif skipped > 0:
		_status.text = "%d tile(s)  (%d skipped)" % [_keys.size(), skipped]
	else:
		_status.text = "%d tile(s) — click to place" % _keys.size()


func _make_thumbnail(tile: WFCTileDef) -> Texture2D:
	if tile.thumbnail_png and tile.thumbnail_png.size() > 0:
		var img := Image.new()
		if img.load_png_from_buffer(tile.thumbnail_png) == OK:
			return ImageTexture.create_from_image(img)
	return _placeholder_thumbnail(tile)


## Generate a flat-colour placeholder for tiles with no embedded thumbnail.
## Hashes the tile name so different tiles get distinguishable colours.
func _placeholder_thumbnail(tile: WFCTileDef) -> Texture2D:
	var seed_str := tile.tile_name if not tile.tile_name.is_empty() else "?"
	var h := seed_str.hash()
	var c := Color.from_hsv(float(h % 360) / 360.0, 0.4, 0.5)
	var img := Image.create(_THUMB_SIZE.x, _THUMB_SIZE.y, false, Image.FORMAT_RGB8)
	img.fill(c)
	return ImageTexture.create_from_image(img)


func _on_item_activated(idx: int) -> void:
	_emit_place_for(idx)


## Single-click also fires a place request — Tiles panel is meant to be a
## one-click stamp library, not a multi-step picker.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item := _list.get_item_at_position(_list.get_local_mouse_position(), true)
		if item >= 0:
			_emit_place_for(item)


func _emit_place_for(idx: int) -> void:
	if idx < 0 or idx >= _keys.size():
		return
	var result := AssetSyncManager.tile_from_cache(_keys[idx])
	var tile: WFCTileDef = result.get("tile") if not result.is_empty() else null
	if not tile:
		_status.text = "Failed to load: %s" % _keys[idx]
		return
	tile_place_requested.emit(tile)
