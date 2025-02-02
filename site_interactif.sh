#!/bin/bash

cd "$(dirname "$0")"

if [[ -z "$TMUX" ]]; then
	exec tmux new-session "$0"
fi

tmux kill-window -a
tmux new-window -d sh -xc 'while true; do ./createbook.sh; sleep 5; done'
tmux new-window -d hugo server
update-submodule

s(){
	"$@" >/dev/null 2>&1 &
	disown
}

term(){
	gnome-terminal -e "$*"
}

pause(){
	echo
	echo -e "\033[0;32mOpération terminée, pour continuer appuyez sur ENTREE\033[0m"
	read
}

update-submodule(){
	git submodule update --remote --force --init publish
	(
		cd publish
		git checkout --detach
		git branch -D gh-pages
		git checkout -b gh-pages
	)
}

interactive_gallery_coments(){
	( cd "$1"
        echo -n "Description pour l'image: "
        read prefix
        while true; do
	        for image in $prefix*; do
	          case "$image" in
	            *.thumbnail.*|*.txt)
	              continue
	              ;;
	          esac

	          descfile="${image%.*}.txt"
	          desc="$(cat "$descfile" 2>/dev/null)"

	          echo
	          echo "Description pour $image"
	          echo "(laisser vide pour ne rien changer, Ctrl-C pour annuler)"
	          if [[ -n "$desc" ]]; then
	            echo "Description actuelle: $desc"
	          else
	            echo "Pas de description actuelle"
	          fi
	          echo -n "==> "
	          trap "break; trap - INT" INT
	          read desc
	          trap - INT

	          if [[ -n "$desc" ]]; then
	            echo "$desc" >"$descfile"
	          fi
	        done

          echo
          echo "(laisser vide pour revenir au menu)"
          echo -n "Description pour une autre image: "
          read prefix
          if [ -z "$prefix" ]; then
            break
          fi
        done
       	)
}

while true; do
	clear
	echo "100% massif"
	echo "==========="
	echo "0. Quitter"
	echo "1. Voir le site en cours de construction"
	echo "2. Publier le site"
	echo "3. Mettre des commentaires aux photos"
	echo
	echo -n "Choix: "
	read ans
	case "$ans" in
		r)
			exec "$0" "$@"
			;;
		0)
			tmux kill-window -a
			exit 0
			;;
		1)
			s firefox http://localhost:1313/
			;;
		2)
			echo
			echo "Quelle modification avez vous faite ?"
			echo -n "Message : "
			read msg
			(
				update-submodule
				set -e -x
				./createbook.sh
				hugo
				./deploy.sh
				git add -A
				git commit -m "${msg:-Automatic commit}"
				git remote -v
				git push origin HEAD
			)
			pause
			;;
		3)
			interactive_gallery_coments static/images/gallery
			;;
		*)
			echo -n "Choix invalide, veuillez choir un numéro"
			sleep 0.5
			echo -n .
			sleep 0.5
			echo -n .
			sleep 0.5
			echo -n .
			sleep 0.5
			;;
	esac
done

