class_name BadgeType
extends PanelContainer
## La pastille colorée d'un type d'alternant (Dev, Data, Product, Marketing,
## Design, Staff, Neutre). La couleur et le libellé viennent de PaletteUi, les
## alias (&"com" = &"marketing") d'Affinites.

@export var type: StringName = &"neutre":
	set(valeur):
		type = valeur
		_appliquer()

@onready var _libelle: Label = %Libelle

func _ready() -> void:
	_appliquer()

## Change le type affiché.
func definir(p_type: StringName) -> void:
	type = p_type

func _appliquer() -> void:
	if _libelle == null:
		return
	var couleur := PaletteUi.couleur_type(type)
	_libelle.text = PaletteUi.libelle_type(type)
	var cadre := StyleBoxFlat.new()
	cadre.bg_color = couleur
	cadre.border_color = PaletteUi.assombrir(couleur)
	cadre.set_border_width_all(1)
	cadre.content_margin_left = 2.0
	cadre.content_margin_right = 2.0
	cadre.content_margin_top = 0.0
	cadre.content_margin_bottom = 0.0
	add_theme_stylebox_override("panel", cadre)
	# Texte sombre sur pastille claire, clair sur pastille sombre.
	_libelle.add_theme_color_override(
		"font_color",
		PaletteUi.FOND if couleur.get_luminance() > 0.5 else PaletteUi.TEXTE
	)
