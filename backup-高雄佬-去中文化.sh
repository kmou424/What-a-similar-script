#!/system/bin/sh
[[ $(id -u) -ne 0 ]] && echo "Root " && exit 1
[[ -z $(echo ${0%/*} | grep -v 'mt') ]] && echo " " && exit 1
[[ ! -d ${0%/*}/tools ]] && echo "${0%/*}/tools" && exit 1
# Load Settings Variables
. ${0%/*}/tools/bin.sh
i=1
txt="${0%/*}/Apkname.txt"
Open_apps=$(dumpsys window | grep -w mCurrentFocus | egrep -oh "[^ ]*/[^//}]+" | cut -f 1 -d "/")
[[ ! -e $txt ]] && echo "$txt" && exit 1
r=$(cat $txt | grep -v "#" | sed -e '/^$/d' | sed -n '$=')
[[ -n $r ]] && h=$r
[[ -z $r ]] && echo "..Apkname.txt" && exit 0
path="/sdcard/Android"
path2="/data/user/0"
Backup="${0%/*}/Backup"
[[ ! -d $Backup ]] && mkdir "$Backup"
filesize=$(du -k -s $Backup | awk '{print $1}')
[[ ! -e $Backup/name.txt ]] && echo "## #xxxxxxxx " >$Backup/name.txt
#
Quantity=0
lz4 () {
	tar -cPpf - "$2" 2>/dev/null | pv -terb >"$1.tar.lz4"
}
zst () {
	tar -cPpf - "$2" 2>/dev/null | pv -terb | zstd -r -T0 -0 -q >"$1.tar.zst"
}
#Everything is Ok#z 2>&1
#echo
echoRgb() {
	if [[ -n $2 ]]; then
		if [[ $3 = 1 ]]; then
			echo -e "\e[1;32m $1\e[0m"
		else
			echo -e "\e[1;31m $1\e[0m"
		fi
	else
		echo -e "\e[1;${bn}m $1\e[0m"
	fi
}
#
echo_log() {
	if [[ $? = 0 ]]; then
		echoRgb "$1" "0" "1"
		result=0
	else
		echoRgb "$1" "0" "0"
		result=1
	fi
}
#
endtime() {
	#
	case $1 in
	1) starttime=$starttime1 ;;
	2) starttime=$starttime2 ;;
	esac
	endtime=$(date "+%Y-%m-%d %H:%M:%S")
	duration=$(echo $(($(date +%s -d "${endtime}") - $(date +%s -d "${starttime}"))) | awk '{t=split("60  60  24  999 ",a);for(n=1;n<t;n+=2){if($1==0)break;s=$1%a[n]a[n+1]s;$1=int($1/a[n])}print s}')
	[[ -n $duration ]] && echoRgb "$2:$duration" || echoRgb "$2:0"
}
Package_names() {
	[[ -n $1 ]] && t1="$1"
	t2=$(appinfo -o pn -pn $t1 | head -1)
	[[ -n $t2 ]] && [[ $t2 = $1 ]] && echo $t2
}


get_version() {
	local version
	local branch
	while :; do
		version="$(getevent -qlc 1 | awk '{ print $3 }')"
		case "$version" in
		KEY_VOLUMEUP)
			branch="yes"
			;;
		KEY_VOLUMEDOWN)
			branch="no"
			;;
		*)
			continue
			;;
		esac
		echo $branch
		break
	done
}
#
Backup-data() {
	if [[ -d $path/$1/$name ]]; then
		if [[ ! -e $Backup/$name/$1size.txt ]]; then
			echoRgb "${name2} $path/$1/"
			lz4 "$name-$1" $path/$1/$name
			echo_log "$name2 $path/$1"
			if [[ $result = 0 ]]; then
				echo $(du -k -s $path/$1/$name | awk '{print $1}') >$Backup/$name/$1size.txt
			else
				echoRgb "lz4zstd"
				zst "$name-$1" $path/$1/$name
				echo_log "$name2 $path/$1"
				[[ $result = 0 ]] && echo $(du -k -s $path/$1/$name | awk '{print $1}') >$Backup/$name/$1size.txt
			fi
		else
			if [[ ! $(cat $Backup/$name/$1size.txt) = $(du -k -s $path/$1/$name | awk '{print $1}') ]]; then
				echoRgb "${name2} $path/$1/"
				lz4 "$name-$1" $path/$1/$name
				echo_log "$name2 $path/$1"
				if [[ $result = 0 ]]; then
					echo $(du -k -s $path/$1/$name | awk '{print $1}') >$Backup/$name/$1size.txt
				else
					echoRgb "lz4zstd"
					zst "$name-$1" $path/$1/$name
					echo_log "$name2 $path/$1"
					[[ $result = 0 ]] && echo $(du -k -s $path/$1/$name | awk '{print $1}') >$Backup/$name/$1size.txt
				fi
			else
				echoRgb "$name2 $1 "
			fi
		fi
	else
		echoRgb "$path/$1 "
	fi
}
#apk
Backup-apk() {
	#APP
	[[ ! -d $Backup/$name ]] && mkdir "$Backup/$name"
	cd $Backup/$name
	#apk
	echoRgb "[ ${name2} APK ]"
	if [[ $name = com.android.chrome ]]; then
		#apk ,apk
		ReservedNum=1
		FileDir=/data/app/*/com.google.android.trichromelibrary_*/base.apk
		FileNum=$(ls -l $FileDir | grep ^- | wc -l)
		while [[ $FileNum -gt $ReservedNum ]]; do
			OldFile=$(ls -rt $FileDir | head -1)
			echoRgb ":"$OldFile
			rm -rf $OldFile
			let "FileNum--"
		done
		ls $FileDir | while read t; do
			if [[ -e $t ]]; then
				echoRgb "com.google.android.trichromelibrary"
				cp -r "$t" "$Backup/$name/nmsl.apk"
				echo_log "Apk"
			fi
		done
	fi
	if [[ ! -e $Backup/$name/apk-version.txt ]]; then
		[[ -z $(cat $Backup/name.txt | grep -v "#" | sed -e '/^$/d' | grep -w "$name" | head -1) ]] && echo "$name2  $name" >>$Backup/name.txt
		echoRgb "$1"
		echoRgb "$(pm path "$name" | cut -f2 -d ':' | wc -l)Apk"
		cp -r $(pm path "$name" | cut -f2 -d ':') "$Backup/$name"
		echo_log "Apk"
		[[ $result = 0 ]] && echo $(pm dump $name | grep -m 1 versionName | sed -n 's/.*=//p') >$Backup/$name/apk-version.txt
	else
		if [[ ! $(cat $Backup/$name/apk-version.txt) = $(pm dump $name | grep -m 1 versionName | sed -n 's/.*=//p') ]]; then
			[[ -z $(cat $Backup/name.txt | grep -v "#" | sed -e '/^$/d' | grep -w "$name" | head -1) ]] && echo "$name2  $name" >>$Backup/name.txt
			echoRgb "$1"
			echoRgb "$(pm path "$name" | cut -f2 -d ':' | wc -l)Apk"
			cp -r $(pm path "$name" | cut -f2 -d ':') "$Backup/$name"
			echo_log "Apk"
			[[ $result = 0 ]] && echo $(pm dump $name | grep -m 1 versionName | sed -n 's/.*=//p') >$Backup/$name/apk-version.txt
		else
			[[ -z $(cat $Backup/name.txt | grep -v "#" | sed -e '/^$/d' | grep -w "$name" | head -1) ]] && echo "$name2  $name" >>$Backup/name.txt
			echoRgb "$name2 Apk "
		fi
	fi
}
echoRgb "split apk(apk)"
echoRgb ""
echoRgb ""
if [[ $(get_version) = yes ]]; then
	C=yes
else
	C=no
fi
[[ $C = yes ]] && echoRgb "" || echoRgb ""
sleep 1.5
echoRgb " "
echoRgb ""
if [[ $(get_version) = yes ]]; then
	B=yes
else
	B=no
fi
[[ $B = yes ]] && echoRgb "" || echoRgb ""
bn=37
#$txt
#
starttime1=$(date +"%Y-%m-%d %H:%M:%S")
{
while [[ $i -le $h ]]; do
	#let bn++
	#[[ $bn -ge 37 ]] && bn=31
	echoRgb "$i $h $(($h - $i))"
	name=$(cat $txt | grep -v "#" | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $2}')
	name2=$(cat $txt | grep -v "#" | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $1}')
	[[ -z $name ]] && echoRgb "! name.txt" "0" "0" && exit 1
	pkg=$(Package_names "$name")
	if [[ -n $pkg ]]; then
		starttime2=$(date +"%Y-%m-%d %H:%M:%S")
		echoRgb "$name2 ($name)"
		[[ $pkg = com.tencent.mobileqq ]] && echo "QQ" || [[ $pkg = com.tencent.mm ]] && echo "WX"
		if [[ ! -d $Backup/tools ]]; then
			mkdir -p $Backup/tools
			cp -r ${0%/*}/tools/* $Backup/tools
		fi
		[[ ! -e $Backup/.sh ]] && cp -r ${0%/*}/tools/restore $Backup/.sh
		#
		if [[ $(pm path "$name" | cut -f2 -d ':' | wc -l) = 1 ]]; then
			if [[ $C = no ]]; then
				[[ ! $name = $Open_apps ]] && am force-stop $name
				Backup-apk "$name2Split Apk"
				D=1
			else
				echoRgb "$name2Split Apk"
				D=
			fi
		else
			[[ ! $name = $Open_apps ]] && am force-stop $name
			Backup-apk "$name2Split Apk"
			D=1
		fi
		#Mt or termux
		if [[ $name = bin.mt.plus || $name = com.termux || $name = com.mixplorer.silver ]]; then
			 if [[ -e $Backup/$name/base.apk ]]; then
				cp -r "$Backup/$name/base.apk" "$Backup/$name.apk"
			fi
		fi
		if [[ $B = yes && -n $D ]]; then
			echoRgb "[ ${name2} Sdcard ]"
			#data
			Backup-data data
			#obb
			Backup-data obb
		fi
		#user
		if [[ -d /data/user/0/$name && -n $D ]]; then
			echoRgb "[ ${name2} user ]"
			if [[ ! -e $Backup/$name/usersize.txt ]]; then
				tar -cPpf - "/data/user/0/$name" --exclude="$name/cache" --exclude="$name/lib" 2>/dev/null | pv -terb >"$name-user.tar.lz4"
				echo_log "user/data/user/0/$name"
				if [[ $result = 0 ]]; then
					echo $(du -k -s /data/user/0/$name | awk '{print $1}') >$Backup/$name/usersize.txt
				else
					echoRgb "lz4zstd"
					tar --exclude="$name/cache" --exclude="$name/lib" -cPpf - "/data/user/0/$name" 2>/dev/null | pv -terb | zstd -r -T0 -0 -q >"$name-user.tar.zst"
					echo_log "user/data/user/0/$name"
					[[ $result = 0 ]] && echo $(du -k -s /data/user/0/$name | awk '{print $1}') >$Backup/$name/usersize.txt
				fi
			else
				if [[ ! $(cat $Backup/$name/usersize.txt) = $(du -k -s /data/user/0/$name | awk '{print $1}') ]]; then
					tar -cPpf - "/data/user/0/$name" --exclude="$name/cache" --exclude="$name/lib" 2>/dev/null | pv -terb >"$name-user.tar.lz4"
					echo_log "user/data/user/0/$name"
					if [[ $result = 0 ]]; then
						echo $(du -k -s /data/user/0/$name | awk '{print $1}') >$Backup/$name/usersize.txt
					else
						echoRgb "lz4zstd"
						tar --exclude="$name/cache" --exclude="$name/lib" -cPpf - "/data/user/0/$name" 2>/dev/null | pv -terb | zstd -r -T0 -0 -q >"$name-user.tar.zst"
						echo_log "user/data/user/0/$name"
						[[ $result = 0 ]] && echo $(du -k -s /data/user/0/$name | awk '{print $1}') >$Backup/$name/usersize.txt
					fi
				else
					echoRgb "$name2 user "
				fi
			fi
		fi
		endtime 2 "$name2"
	else
		echoRgb "$name2[$name]" "0" "0"
	fi
	echo
	let i++
done
#
filesizee=$(du -k -s $Backup | awk '{print $1}')
dsize=$(($((filesizee - filesize)) / 1024))
echoRgb ":$Backup"
echoRgb "$(du -k -s -h $Backup | awk '{print $1}')"
if [[ $dsize -gt 0 ]]; then
	if [[ $((dsize / 1024)) -gt 0 ]]; then
		echoRgb ": $((dsize / 1024))gb"
	else
		echoRgb ": ${dsize}mb"
	fi
else
	echoRgb ": $(($((filesizee - filesize)) * 1000 / 1024))kb"
fi
echoRgb ""
endtime 1 ""
exit 0
}&
