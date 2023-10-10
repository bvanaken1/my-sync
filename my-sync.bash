#!/bin/bash
# Script créé par Brice VAN AKEN

# Donne les informations d'utilisations du script
usage() {
    echo "Usage: $0 [</source>] [</destination>] "
    exit 1
}

# Effectue l'arboresence et stocke les informations dans /backup/.file
tree() {
    mapfile -t folder < <(find "$1" -type d -printf "%T+ %p\n")
    for ((i = 0; i < ${#folder[@]}; i++)); do
        echo "${folder[i]}" >>"$2/backup/.files"
        mapfile -t foldername < <(find "$1" -type d)
        mapfile -t files < <(find "${foldername[i]}" -maxdepth 1 -type f -printf "%T+ %s %p " -exec sh -c 'md5sum "$1" | awk "{print \$1}"' sh {} \;)
        for ((y = 0; y < ${#files[@]}; y++)); do
            echo "${files[y]}" >>"$2/backup/.files"
        done
    done
}

# Compare l'arborescence, supprime et copie les fichiers modifiés
# ET supprime les fichiers supprimés dans le dossier source à la destination, puis reconstruit l'arbre
compareTree() {
    mapfile -t folder < <(find "$1" -type d -printf "%T+ %p\n")
    for ((i = 0; i < ${#folder[@]}; i++)); do
        mapfile -t foldername < <(find "$1" -type d)
        mapfile -t files < <(find "${foldername[i]}" -maxdepth 1 -type f -printf "%T+ %s %p " -exec sh -c 'md5sum "$1" | awk "{print \$1}"' sh {} \;)
        mapfile -t filepath < <(find "${foldername[i]}" -maxdepth 1 -type f)
        for ((y = 0; y < ${#files[@]}; y++)); do
            if (($(grep -c "${files[y]}" "$2"/backup/.files) == 0)); then
                newpath=$(sed s/"$1"/"$2""\/backup"/g <<<"${filepath[y]}")
                rm -f "$newpath"
                cp --preserve -r "${filepath[y]}" "$newpath"
            fi
        done
    done
    mapfile -t filestoremove < <(diff -r -q code/ "$2""/backup" | sed "s/.*$2//" | sed 's/: /\//g')
    for ((x = 0; x < ${#filestoremove[@]}; x++)); do rm -f "$2""${filestoremove[x]}"; done
    tree "$1" "$2"
}

# Vérification des paramètres passés en argument
if (($# != 2)); then usage; fi

# Vérification du répertoire source
if [ ! -d "$1" ]; then
    echo "Le chemin source n'existe pas"
    exit 1
fi

# Vérification du répertoire de destination
if [ ! -d "$2" ]; then mkdir -p "$2"; fi

# Vérification droit lecture source
if [ ! -r "$1" ] || [ ! -w "$2" ]; then
    echo "Le chemin source n'est pas lisible"
    exit 1
fi

# Vérification droit écriture / lecture destination
if [ ! -w "$2" ] || [ ! -r "$2" ]; then
    echo "Impossible d'écrire / lire sur le chemin destination"
    exit 1
fi

# Vérification de la présence du dossier backup
if [ ! -d "$2/backup" ]; then
    mkdir "$2/backup"
    touch "$2/backup/.files"
    cp --preserve -r "$1/." "$2/backup"
    tree "$1" "$2"
else
    compareTree "$1" "$2"
fi
# Finalisation, copie en hardlink du dossier backup avec la date et l'heure
cp -rl "$2/backup" "$2/backup"_"$(date "+%Y-%m-%d-%H-%M-%S")"
