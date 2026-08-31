extends Control


func enda(whowho):
	show()
	if whowho == "1":
		$Label.text = "Muehehehe The bad guys won :)"
	elif whowho == "2":
		$Label.text = "Yall just lucky ngl"
	await get_tree().create_timer(5).timeout
	get_tree().quit()
