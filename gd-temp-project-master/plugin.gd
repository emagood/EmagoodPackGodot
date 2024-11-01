extends Control

var helpers := preload("res://project-manager/inspect/helpers.gd")
var gdx := preload("res://editor-only/included/gdx.gd").new()
var Paths := preload("res://editor-only/included/paths.gd")

var hbox := HBoxContainer.new()

func _enter_tree() -> void:
	var project_list: Node = helpers.extract_node([0, 1, 0, 1, 0, 1, 0, 0])
	var vbox: VBoxContainer = project_list.get_child(0, true)
	var temp_btn := Button.new()
	
	
	gdx.render(func(): return (
		[project_list, [
			[VBoxContainer, {
				size_flags_horizontal = SIZE_EXPAND_FILL
			}, [
				[hbox, {
					#size_flags_horizontal = SIZE_SHRINK_END
				}, [
					[Label, {text = "Shortcuts:"}],
					[Button, {
						text = "Temp Project",
						on_pressed = func():
							#if event is InputEventMouseButton:
								#if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
							var base_path := Paths.global.path_join("project-manager/temp-project/.project/")
							erase_dir(base_path)
							var new_path := helpers.create_project(base_path)
							var cfg := ConfigFile.new()
							cfg.load(new_path)
							cfg.set_value(
								"rendering", 
								"renderer/rendering_method", 
								"gl_compatibility"
							)
							cfg.save(new_path)
							open_project(new_path)
							#temp_btn.disabled = true
							pass,
					}],
					[Button, {
						text = "Global Project",
						on_pressed = func():
							open_project(Paths.global.path_join("project.godot"))
							pass,
					}]
				]],
				[vbox]
			]]
		]]
	))

func erase_dir(path: String):
	print('erasing ', path)
	for dname in DirAccess.get_directories_at(path):
		erase_dir(path.path_join(dname))
	for fname in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(fname))
	DirAccess.remove_absolute(path)

func open_project(path: String):
	OS.create_instance([path, "-editor"])
	get_tree().quit()

func _exit_tree() -> void:
	hbox.queue_free()
