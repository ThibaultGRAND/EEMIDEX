extends SceneTree

func _initialize() -> void:
	var gs: Node = root.get_node_or_null("GameState")
	if gs == null:
		print("ECHEC : autoload GameState absent")
		quit()
		return
	gs.jouer_musique(&"exploration")
	var lecteur: AudioStreamPlayer = gs.get_node("Musique")
	print("1) piste=%s joue=%s" % [lecteur.stream.resource_path, lecteur.playing])
	await create_timer(1.0).timeout
	gs.jouer_musique(&"boutique")
	print("2) demande boutique, courante=%s" % gs.musique_courante)
	await create_timer(1.5).timeout
	print("3) piste=%s joue=%s volume=%.1f" % [lecteur.stream.resource_path, lecteur.playing, lecteur.volume_db])
	gs.jouer_musique(&"boutique")
	print("4) redemande boutique : piste=%s joue=%s" % [lecteur.stream.resource_path, lecteur.playing])
	quit()
