pot:
	@pybabel extract \
		--project gdfxr \
		--version 1.0 \
		--msgid-bugs-address 'timothyqiu32@gmail.com' \
		--copyright-holder 'Haoyu Qiu' \
		--add-location file \
		-F babel.cfg \
		-k tr \
		-k text \
		-k label \
		-k hint_tooltip \
		-k options \
		-o addons/gdfxr/editor/translations/gdfxr.pot \
		addons/gdfxr/editor
