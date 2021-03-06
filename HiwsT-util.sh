#!/bin/bash

# Enemble d'utilitaires pour la gestion des utilisateurs linux, rutorrent et cakebox
# L'ajout ou la suppression d'utilisateurs
# Changement de mot de passe
# ....

# Version 1.0
# https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-


#############################
#       Fonctions
#############################
REPWEB="/var/www/html"
REPAPA2="/etc/apache2"
REPLANCE=$(echo `pwd`)

__verifSaisie() {
if [[ $1 =~ ^[a-zA-Z0-9]{2,15}$ ]]; then
	verifOk="o"
else 	echo "Uniquement des caractères alphanumériques"
	echo "Entre 2 et 15 caractères"
	verifOk="n"
fi
}

__ouinon() {
local tmp=""; local yno=""
until [[ $tmp == "ok" ]]; do
echo
echo -n "Voulez-vous continuer ? (o/n) "; read yno
case $yno in
	[nN] | [nN][oO][nN])
		echo "A bientôt !"
		exit 1
	;;
	[Oo] | [Oo][Uu][Ii])
		echo
		tmp="ok"
		sleep 1
	;;
	*)
		echo "Entrée invalide"
		sleep 1
	;;
esac
done
}    #  fin ouinon

__messageErreur() {
	echo; echo "Consulter le wiki"
	echo "https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
}  # fin messageErreur

__IDuser() {    # saisie ID et PW  ruto/cake

echo
local tmp=""; local tmp2=""; local yno=""
until [[ $tmp == "ok" ]]; do
	# traitement rutorrent ----------------------------------------------------
	if [[ $1 == "ruTorrent" ]]; then
		echo -n "Choisir un nom d'utilisateur $1 (ni espace ni \) : "
		read user
		__verifSaisie $user
		if [[ $verifOk == "o" ]]; then
			# user linux ?
			egrep "^$user" /etc/passwd >/dev/null
			userL=$?
			# user ruTorrent ?
			egrep "^$user:rutorrent" /etc/apache2/.htpasswd > /dev/null
			userR=$?
			if [[ $userL -eq 0 ]]; then
				echo "Il existe déjà un utilisateur Linux $user "
				echo "Vous ne pouvez pas en créer un deuxième"
				yno="N"
			elif [[ $userR -eq 0 ]]; then
					echo "$user est déjà un utilisateur ruTorrent"
					echo "Vous ne pouvez pas en créer un deuxième"
					yno="N"
				else
					echo -n "Vous confirmez '$user' comme nom d'utilisateur ? (o/n) "
					read yno
				fi
			fi
		fi
	#     traitement cakebox ------------------------------------------------------
	if [[ $1 == "Cakebox" ]]; then
		echo -n "Choisir un nom d'utilisateur $1 (ni espace ni \) : "
		read user
		__verifSaisie $user
		if [[ $verifOk == "o" ]]; then
			# user cakebox ?
			egrep "^$user" /var/www/html/cakebox/public/.htpasswd > /dev/null
			userC=$?
			#  déjà un user linux ?
			egrep "^$user" /etc/passwd >/dev/null
			userL=$?
			#  déjà user rutorrent ?
			egrep "^$user:rutorrent" /etc/apache2/.htpasswd > /dev/null
			userR=$?
			if [ $userL -ne 0 -o $userC -eq 0 ]; then
				# pas de ul ou existe uc NON
				echo "$user n'est pas un utilisateur Linux ou"
				echo "$user est déjà un utilisateur Cakebox."
				echo "Impossible de créer un utilisateur Cakebox sous ce nom."
				yno="N"
			elif [[ userR -ne 0 ]]; then
					# existe ul  pas de ur  pas de uc NON
					echo "$user est bien un utilisateur Linux, mais"
					echo "$user n'est pas un utilisateur ruTorrent"
					echo "Impossible de créer un utilisateur Cakebox sous ce nom."
					yno="N"
				else
					# existe ul exite ur pas de uc OUI
					echo
					echo -n "Vous confirmez '$user' comme nom d'utilisateur ? (o/n) "
					read yno
				fi
			fi
		fi
 #    fin traitement différent -----------------------------------------

	case $yno in
		[Oo] | [Oo][Uu][Ii] )   # saisie ID et PW d'un utilisateur
			until [[ $tmp2 == "ok" ]]; do
				echo -n "Choisissez un mot de passe (ni espace ni \) : "
				read pw
				echo -n "Resaisissez ce mot de passe : "
				read pw2
				case $pw2 in
					$pw)
						tmp2="ok"; tmp="ok"
						sleep 2
					;;
					*)
						echo "Les deux saisies du mot de passe ne sont pas identiques. Recommencez"
						echo
						sleep 1
					;;
				esac
			done  # fin saisie d'un utilisateur
		;;
		[nN] | [nN][oO][nN])
			echo "Nom d'utilisateur invalidé. Reprendre la saisie"
			echo
			sleep 1
		;;
		esac
	if [[ $verifOk == "n" ]]; then
		#statements
		echo "Entrée invalide"
		sleep 1
	fi
done

if [[ $1 == "ruTorrent" ]]; then
	userRuto=$user; pwRuto=$pw
else
	userCake=$user; pwCake=$pw
fi
}  # fin IDuser

__creaUserRuto () {

echo
echo "**************************************"
echo "|  Création d'un nouvel utilisateur  |"
echo "|            ruTorrent               |"
echo "**************************************"
echo
echo -e "\tNom utilisateur : $userRuto"
echo -e "\tMot de passe    : $pwRuto"
echo
sleep 2

#  créer l'utilisateur linux $userRuto  ---------------------------------

# Ajout du group sftp si n'existe pas
#  group sftp pour interdire de sortir de /home/user en sftp
egrep "^sftp" /etc/group > /dev/null
if [[ $? -ne 0 ]]; then
	addgroup sftp
fi

pass=$(perl -e 'print crypt($ARGV[0], "pwRuto")' $pwRuto)
useradd -m -G sftp -p $pass $userRuto
if [[ $? -ne 0 ]]; then
	echo "Impossible de créer l'utilisateur ruTorrent $userRuto"
	echo "Erreur sur 'useradd'"
	__messageErreur
	exit 1
fi

# echo "bash" >> /home/$userRuto/.profile

echo "Utilisateur linux $userRuto créé"
echo

mkdir -p /home/$userRuto/downloads/watch
mkdir -p /home/$userRuto/downloads/.session
chown -R $userRuto:$userRuto /home/$userRuto/

echo "Répertoire/sous-répertoires /home/$userRuto créé"
echo
#  rtorrent ------------------------------------------------

# incrémenter le port, écrir le fichier témoin
if [ -e /var/www/html/rutorrent/conf/scgi_port ]; then
	port=$(cat /var/www/html/rutorrent/conf/scgi_port)
else 	port=5000
fi

let "port += 1"
echo $port > /var/www/html/rutorrent/conf/scgi_port

# rtorrent.rc
cp $REPLANCE/fichiers-conf/rto_rtorrent.rc /home/$userRuto/.rtorrent.rc
sed -i 's/<username>/'$userRuto'/g' /home/$userRuto/.rtorrent.rc
sed -i 's/scgi_port.*/scgi_port = 127.0.0.1:'$port'/' /home/$userRuto/.rtorrent.rc

echo "/home/$userRuto/rtorrent.rc créé"
echo

#  fichiers daemon rtorrent
#  créer rtorrent.conf
cp $REPLANCE/fichiers-conf/rto_rtorrent.conf /etc/init/$userRuto-rtorrent.conf
chmod u+rwx,g+rwx,o+rx  /etc/init/$userRuto-rtorrent.conf
sed -i 's/<username>/'$userRuto'/g' /etc/init/$userRuto-rtorrent.conf

#  rtorrentd.sh modifié   il faut redonner aux users bash
sed -i '/## bash/ a\          usermod -s \/bin\/bash '$userRuto'' /etc/init.d/rtorrentd.sh
sed -i '/## screen/ a\          su --command="screen -dmS '$userRuto'-rtd rtorrent" "'$userRuto'"' /etc/init.d/rtorrentd.sh
sed -i '/## false/ a\          usermod -s /bin/false '$userRuto'' /etc/init.d/rtorrentd.sh
systemctl daemon-reload
service rtorrentd restart
if [[ $? -eq 0 ]]; then
	echo "rtorrent en daemon modifié et fonctionne."
	echo
else	echo "Un problème est survenu."
	ps aux | grep -e '.*torrent$'
	echo
	service rtorrentd status
	__messageErreur
	exit 1
fi

#  ruTorrent ------------------------------------------------------------------

# dossier conf/users/userRuto
mkdir -p /var/www/html/rutorrent/conf/users/$userRuto
cp /var/www/html/rutorrent/conf/access.ini /var/www/html/rutorrent/conf/plugins.ini /var/www/html/rutorrent/conf/users/$userRuto
cp $REPLANCE/fichiers-conf/ruto_multi_config.php /var/www/html/rutorrent/conf/users/$userRuto/config.php
sed -i -e 's/<port>/'$port'/' -e 's/<username>/'$userRuto'/' /var/www/html/rutorrent/conf/users/$userRuto/config.php

# plugins
# echo -e "\n    [linkcakebox]\n    enabled = no" >> $REPWEB/rutorrent/conf/users/$userRuto/plugins.ini

echo "Dossier users/$userRuto sur ruTorrent crée"
echo

# sécuriser ruTorrent
(echo -n "$userRuto:rutorrent:" && echo -n "$userRuto:rutorrent:$pwRuto" | md5sum) >> /etc/apache2/.htpasswd
sed -i 's/[ ]*-$//' /etc/apache2/.htpasswd
service apache2 restart
if [[ $? -eq o ]]; then
	echo "Mot de passe de $userRuto créé"
	echo
else	service apache2 status
	__messageErreur
	exit 1
fi

# modif pour sftp / sécu sftp -------------------------------------------------------

# pour user en sftp interdit le shell en fin de traitement; bloque le daemon
usermod -s /bin/false $userRuto
# pour interdire de sortir de /home/user  en sftp
chown root:root /home/$userRuto
chmod 0755 /home/$userRuto

# modif sshd.config
sed -i 's/AllowUsers.*/& '$userRuto'/' /etc/ssh/sshd_config
sed -i 's|^Subsystem sftp /usr/lib/openssh/sftp-server|#  &|' /etc/ssh/sshd_config
if [[ `cat /etc/ssh/sshd_config | grep "Subsystem  sftp  internal-sftp"` == "" ]]; then
	echo -e "Subsystem  sftp  internal-sftp\nMatch Group sftp\n ChrootDirectory %h\n ForceCommand internal-sftp\n AllowTcpForwarding no" >> /etc/ssh/sshd_config
fi
service sshd restart > /dev/null
# service ssh status
echo "Sécurisation SFTP faite : seulement accès a /home/$userRuto"
}   #  fin creauserruto


 __creaUserCake() {
echo
echo "**************************************"
echo "|  Création d'un nouvel utilisateur  |"
echo "|             Cakebox                |"
echo "**************************************"
echo
echo -e "\tNom utilisateur : $userCake"
echo -e "\tMot de passe    : $pwCake"
echo
sleep 2

# - copier conf/user.php modif rep à scanner
cp $REPWEB/cakebox/config/default.php.dist $REPWEB/cakebox/config/$userCake.php
sed -i "s|\(\$app\[\"cakebox.root\"\].*\)|\$app\[\"cakebox.root\"\] = \"/home/$userCake/downloads/\";|" $REPWEB/cakebox/config/$userCake.php
sed -i "s|\(\$app\[\"player.default_type\"\].*\)|\$app\[\"player.default_type\"\] = \"vlc\";|" $REPWEB/cakebox/config/$userCake.php
chown -R www-data:www-data $REPWEB/cakebox/config
echo
echo "cakebox/config/$userCake.php créé"
echo
# - ajout dans cakebox.conf apache
sed -i '/ErrorLog.*/ i\\n    Alias /access /home/'$userCake'/downloads/\n    <Directory "/home/'$userCake'/downloads">\n        Options -Indexes\n\n        <IfVersion >= 2.4>\n            Require all granted\n        </IfVersion>\n        <IfVersion < 2.4>\n            Order allow,deny\n            Allow from all\n        </IfVersion>\n        Satisfy Any\n\n        Header set Content-Disposition "attachment"\n\n    </Directory>\n' $REPAPA2/sites-available/cakebox.conf
echo
echo "cakebox.conf dans apache modifié"
echo
# mot de passe
htpasswd -b $REPWEB/cakebox/public/.htpasswd $userCake $pwCake
echo
echo "Mot de passe $userCake créé"
echo
 }  # fin __creaUserCake


__suppUserCake() {
# saisie nom sauf si conjoint à la supp rutorrent alors $suppUserCake pas vide
if [[ ! $suppUserCake ]]; then
	local tmp=""
	until [[ $tmp == "ok" ]]; do
		echo
		echo -n "Nom de l'utilisateur Cakebox à supprimer "
		read userCake
		# user cakebox ?
		egrep "^$userCake" /var/www/html/cakebox/public/.htpasswd > /dev/null
		if [[ $? -ne 0 ]]; then
			echo "$userCake n'est pas un utilisateur Cakebox"
		else
			tmp="ok"
		fi
	done
else
	userCake=$suppUserCake
fi

# mot de passe
sed -i "s/^"$userCake".*//" $REPWEB/cakebox/public/.htpasswd
echo "Mot de passe supprimé"
# supprimer dans ckebox.conf
sed -i '/    Alias \/access \/home\/'$userCake'\/downloads\//,/    <\/Directory>/d' $REPAPA2/sites-available/cakebox.conf
echo
echo "cakebox.conf dans apache modifié"
echo
# supprimer le fichier conf/user.php
rm $REPWEB/cakebox/config/$userCake.php
echo
echo "cakebox/config/$userCake.php supprimé"
echo
}  # fin __suppUserCake


__suppUserRuto() {
# saisie nom
local tmp=""
until [[ $tmp == "ok" ]]; do
	echo
	echo -n "Nom de l'utilisateur ruTorrent à supprimer "
	read userRuto
	# user ruto ?
	egrep "^$userRuto:rutorrent" $REPAPA2/.htpasswd > /dev/null
	if [[ $? -ne 0 ]]; then
		echo "$userRuto n'est pas un utilisateur ruTorrent"
	else
		tmp="ok"
	fi
done

# suppression du user allowed dans sshd_config
sed -i '/'$userRuto'/d' /etc/ssh/sshd_config
service sshd restart

# mot de passe rutorrent
sed -i "s/^"$userRuto".*//" $REPAPA2/.htpasswd
echo "Mot de passe supprimé"
echo

# dossier rutorrent/conf/users/userRuto
rm -r $REPWEB/rutorrent/conf/users/$userRuto
echo "Dossier users/$userRuto sur ruTorrent supprimé"
echo

# modif de rtorrentd.sh
sed -i '/.*'$userRuto.*'/d' /etc/init.d/rtorrentd.sh
rm /etc/init/$userRuto-rtorrent.conf

systemctl daemon-reload
service rtorrentd restart
if [[ $? -eq 0 ]]; then
	echo "rtorrent en daemon modifié et fonctionne."
	echo
else	echo "Un problème est survenu."
	ps aux | grep -e '.*torrernt$'
	echo
	service rtorrentd status
	__messageErreur
	exit 1
fi
# Suppression du home et suppression user linux -f le home est root:root
userdel -fr $userRuto
echo "Utilisateur linux et /home/$userRuto supprimé"
}  # fin __suppUserRuto


__saisiePW() {   # pour __changePW
local tmp2=""
	until [[ $tmp2 == "ok" ]]; do
				echo -n "Choisissez un mot de passe (ni espace ni \) : "
				read pw
				echo -n "Resaisissez ce mot de passe : "
				read pw2
				case $pw2 in
					$pw)
						tmp2="ok"
					;;
					*)
						echo "Les deux saisies du mot de passe ne sont pas identiques. Recommencez"
						echo
						sleep 1
					;;
				esac
	done
}  #  fin __saisiePW {

__changePW() {
local typeUser=""; local user=""; local tmp=""

until [[ $tmp == "ok" ]]; do
	echo
	echo "Type d'utilisateur : "
	echo -n "0) sortir  1) Linux  2) ruTorrent  3) Cakebox  4) Liste des utilisateurs : "
	read typeUser

		case $typeUser in
			[1] )
				echo "!!! Mot de passe valable aussi pour ftp !!!"
				echo -n "Nom de l'utilisateur linux : "
				read user
				# user linux ?
				egrep "^$user" /etc/passwd >/dev/null
				if [[ $? -eq 0 ]]; then
					passwd $user
					if [[ $? != 0 ]]; then echo "une erreur c'est produite, mot de passe inchangé"
					else
						echo; echo "Traitement terminé"
						echo "Utilisateur $user"
					fi
				else
					echo
					echo "$user n'est pas un utilisateur linux"
				fi
			;;
			[2] )
				echo -n "Nom de l'utilisateur ruTorrent : "
				read user
				# user ruTorrent ?
				egrep "^$user:rutorrent" $REPAPA2/.htpasswd > /dev/null
				if [[ $? -eq 0 ]]; then
					__saisiePW
					sed -i "s/^"$user".*//" $REPAPA2/.htpasswd
					(echo -n "$user:rutorrent:" && echo -n "$user:rutorrent:$pw" | md5sum) >> /etc/apache2/.htpasswd
					sed -i 's/[ ]*-$//' /etc/apache2/.htpasswd
					# service apache2 restart
						echo; echo "Traitement terminé"
						echo "Utilisateur $user"
						echo "Nouveau mot de passe : $pw"
				else
					echo
					echo "$user n'est pas un utilisateur ruTorrent"
				fi
			;;
			[3] )
				echo -n "Nom de l'utilisateur Cakebox : "
				read user
				# user cakebox ?
				egrep "^$user" /var/www/html/cakebox/public/.htpasswd > /dev/null
				if [[ $? -eq 0 ]]; then
					__saisiePW
					htpasswd -b $REPWEB/cakebox/public/.htpasswd $user $pw
					if [[ $? != 0 ]]; then echo "une erreur c'est produite, mot de passe inchangé"
					else
						echo; echo "Traitement terminé"
						echo "Utilisateur $user"
						echo "Nouveau mot de passe : $pw"
					fi
				else
					echo
					echo "$user n'est pas un utilisateur Cakebox"
				fi
			;;
			[4] )
				. $REPLANCE/insert/listeusers.sh
				sleep 1
			;;
			[0] )
				tmp="ok"
			;;
			* )
				echo "Entrée invalide"
				sleep 1
			;;
		esac
done
}  #  fin __changePW


__menu() {
clear
echo
echo "******************************************"
echo "|                                        |"
echo "|    Hiwst-util Utilitaires seedbox      |"
echo "|         ruTorrent - Cakebox            |"
echo "|                                        |"
echo "|   A utiliser après une installation    |"
echo "|         réalisée avec HiwsT            |"
echo "******************************************"
echo; echo
local tmp=""; choixMenu=""
until [[ $tmp == "ok" ]]; do
	echo
	echo "Voulez-vous"
	echo
	echo -e "\t1)  Ajouter un utilisateur Linux et ruTorrent"
	echo -e "\t2)  Ajouter un utilisateur Cakebox"
	echo -e "\t3)  Ajouter un utilisateur Linux, ruTorrent et Cakebox"
	echo
	echo -e "\t4)  Modifier un mot de passe utilisateur"
	echo -e "\t5)  Supprimer un utilisateur Cakebox"
	echo -e "\t6)  Supprimer un utilisateur ruTorrent (et Linux, Cakebox)"
	echo -e "\t7)  Lister les utilisateurs existants"
	echo
	echo -e "\t8)  Relancer rtorrent manuellement"
	echo -e "\t9)  Diagnostique"
	echo -e "\t10) Rebooter le serveur"
	echo
	echo -e "\t0)  Sortir"
	echo

	echo -n "Votre choix (0 1 2 3 4 5 6 7 8 9 10) "
	read choixMenu
	echo
	case $choixMenu in
		0 )
			tmp2="ok"; tmp="ok"
		;;
		1 )  # + user ruTorrent
			echo
			echo "****************************************"
			echo "|     Ajout d'un utilisateur Linux     |"
			echo "|            et ruTorrent              |"
			echo "****************************************"
			echo
			echo "- Sur ruTorrent il n'aura accès qu'a son"
			echo "  répertoire de téléchargement"
			echo
			echo "- Le nouvel utilisateur aura un accès SFTP"
			echo "  avec son ID et mot de passe, même port"
			echo "  que les autres utilisateurs."
			echo "- Il sera limité à son répertoire"
			echo "- Pas d'accès ssh"
			echo
			__IDuser ruTorrent
			__creaUserRuto

			echo
			echo "Traitement terminé"
			echo "Utilisateur $userRuto crée"
			echo "Mot de passe $pwRuto"
			sleep 1
			tmp2="ok"
		;;
		2 )  # + user cakebox
			echo
			echo "****************************************"
			echo "|    Ajout d'un utilisateur Cakebox    |"
			echo "****************************************"
			echo
			echo "- L'utilisateur devra déjà exister en tant"
			echo "  qu'utilisateur ruTorrent"
			echo "- Le nouvel utilisateur ne pourra scanner"
			echo "  que son répertoire de téléchargement."
			echo
			__IDuser Cakebox
			__creaUserCake
			echo
			echo "Traitement terminé"
			echo "Utilisateur $userCake crée"
			echo "Mot de passe $pwCake"
			sleep 1
			tmp2="ok"
		;;
		3 )  # + user rutorrent et cakebox
			echo
			echo "****************************************"
			echo "|    Ajout d'un utilisateur Linux,     |"
			echo "|       ruTorrent  et Cakebox          |"
			echo "****************************************"
			echo
			echo "- Le nouvel utilisateur aura le même nom et"
			echo "  Mot de passe pour les 3 accès"
			echo
			echo "- Le nouvel utilisateur aura un accès SFTP"
			echo "  avec son ID et mot de passe, même port"
			echo "  que les autres utilisateurs."
			echo "- Il sera limité à son répertoire"
			echo "- Pas d'accès ssh"
			echo
			echo "- Sur ruTorrent il n'aura accès qu'a son"
			echo "  répertoire de téléchargement"
			echo "- Sur Cakebox il ne pourra scanner"
			echo "  que son répertoire de téléchargement."
			echo
			__IDuser ruTorrent
			echo
			__creaUserRuto # + linux
			userCake=$userRuto; pwCake=$pwRuto
			echo
			__creaUserCake
			echo
			echo "Traitement terminé"
			echo "Utilisateur $userCake crée"
			echo "Mot de passe $pwCake"
			sleep 1
			tmp2="ok"
		;;
		4 )
			echo
			echo "********************************"
			echo "|   Changer un mot de passe    |"
			echo "********************************"
			__changePW
			echo
			tmp2="ok"
		;;
		5 )
			echo
			echo "*************************************"
			echo "|   Supprimer utilisateur Cakebox   |"
			echo "*************************************"
			echo
			__suppUserCake
			echo
			echo "Traitement terminé"
			echo "Utilisateur $userCake supprimé"
			sleep 1
			tmp2="ok"
		;;
		6 )
			echo
			echo "*************************************"
			echo "|  Supprimer utilisateur ruTorrent  |"
			echo "|        Cakebox et Linux           |"
			echo "*************************************"
			echo
			echo "ATTENTION le répertoire /home de l'utilisateur"
			echo "va être supprimé !!!!!!!!!!"
			__ouinon
			__suppUserRuto  # + linux
			suppUserCake=$userRuto  # éviter de redemander le nom
			echo    # si plus de user ruto et linux forcément ...
			__suppUserCake
			echo
			echo "Traitement terminé"
			echo "Utilisateur $userRuto supprimé"
			sleep 1
			tmp2="ok"
		;;
		7 )
			echo
			echo "****************************"
			echo "|  Liste des utilisateurs  |"
			echo "****************************"
			echo
			. $REPLANCE/insert/listeusers.sh
			sleep 1
			tmp2="ok"
		;;
		8 )
			echo
			echo "***************************"
			echo "|    rtorrent restart     |"
			echo "***************************"
			echo
			service rtorrentd restart
			service rtorrentd status
			sleep 1
			tmp2="ok"
		;;
		9 )
			echo
			echo "***************************"
			echo "|      Diagnostique       |"
			echo "***************************"
			echo
			. $REPLANCE/insert/diag.sh
			sleep 1
			tmp2="ok"
		;;
		10 )
			echo
			echo "*********************"
			echo "|      Reboot       |"
			echo "*********************"
			echo
			__ouinon
			reboot
		;;
		* )
			echo "Entrée invalide"
			sleep 1
		;;
	esac
done

}   # fin menu

#############################
#     Début du script
#############################

# root ?
if [[ $(id -u) -ne 0 ]]; then
	echo
	echo "Ce script nécessite d'être exécuté avec sudo."
	echo
	echo "id : "`id`
	echo
	exit 1
fi

__menu

echo "Au revoir"
echo
