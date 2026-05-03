class_name FileDialogUtil
extends Object

## Shared FileDialog setup for the standalone editor.
## In the Godot editor, ACCESS_RESOURCES is convenient (browses the project).
## In an exported build, `res://` is the read-only .pck — ACCESS_RESOURCES leaves
## the dialog with nothing browsable and saves fail with ERR_CANT_OPEN (19).
## ACCESS_FILESYSTEM lets users browse and save anywhere on disk.
static func configure_access(dialog: FileDialog) -> void:
	if OS.has_feature("editor"):
		dialog.access = FileDialog.ACCESS_RESOURCES
		return
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	var docs := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if docs != "":
		dialog.current_dir = docs
