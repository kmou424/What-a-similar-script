function createConf(){
echo $'TARGET_BITRATE="2500"
TARGET_FRAMERATE="disable"
TARGET_ZOOM_RATIO="disable"
TARGET_QUALITY="disable"
TARGET_CODEC="libx264"	#libx264 libx265
TARGET_CODEC_PRESET="medium"	#ultrafast superfast veryfast faster fast medium slow slower veryslow
INPUT_FORMAT="mp4|mov"
OUTPUT_FORMAT="mp4"
LOG_NAME="log_video.txt"
OUT_DIR="out"' >> "$1"
}

function loadConf(){
	TARGET_BITRATE="2500"
	TARGET_FRAMERATE="disable"
	TARGET_ZOOM_RATIO="disable"
	TARGET_QUALITY="disable"
	TARGET_CODEC="libx264"
	TARGET_CODEC_PRESET="medium"
	INPUT_FORMAT="mp4|mov"
	OUTPUT_FORMAT="mp4"
	LOG_NAME="log_video.txt"
	OUT_DIR="out"
	if [[ -f "$PWD/toolbox_video.conf" ]];then
			. "$PWD/toolbox_video.conf"
	else
			createConf "$PWD/toolbox_video.conf"
	fi
}

function compressVideo(){
	filename="$1"
	filedir="${filename%/*}"

	cd "$filedir"
	mkdir -p "$filedir/${OUT_DIR}"

	TASK_COUNT=$[$TASK_COUNT+1]

	ORI_WIDTH=$(mediainfo --Output="Video;%Width%" ${filename})
	ORI_HEIGHT=$(mediainfo --Output="Video;%Height%" ${filename})
	ORI_FRAMWRATE=$(mediainfo --Output="Video;%FrameRate%" ${filename})

	if [ "$TARGET_ZOOM_RATIO" != "disable" ] && [ "$TARGET_QUALITY" != "disable" ];then
		echo "错误: 不能同时开启缩放比例(TARGET_ZOOM_RATIO)和画质(TARGET_QUALITY)功能"
		exit 1
	else
		TARGET_WIDTH=$ORI_WIDTH
		TARGET_HEIGHT=$ORI_HEIGHT
	fi

	if [ "$TARGET_ZOOM_RATIO" != "disable" ];then
		if [ -n "$(echo $TARGET_ZOOM_RATIO | sed 's/\.//g' | sed 's/\///g' | sed -n "/^[0-9]\+$/p")" ];then
			if [ $(echo "$TARGET_ZOOM_RATIO > 1.0" | bc) -eq 1 ];then
				echo "错误: 指定的缩放比例大于1.0，视频分辨率将会出现异常"
				exit 1
			fi
			TARGET_WIDTH="iw*${TARGET_ZOOM_RATIO}"
			TARGET_HEIGHT="ih*${TARGET_ZOOM_RATIO}"
		else
			echo "错误: 指定的缩放比例不是数字"
			exit 1
		fi
	else
		TARGET_ZOOM_RATIO_MSG="未指定"
	fi

	if [ "$TARGET_QUALITY" != "disable" ];then
		if [ $ORI_HEIGHT -gt $ORI_WIDTH ];then
			ORI_RESOLUTION=$ORI_WIDTH
			RESOLUTION="width"
		else
			ORI_RESOLUTION=$ORI_HEIGHT
			RESOLUTION="height"
		fi
		case $TARGET_QUALITY in
		 sd-|SD-|480p-|480P-)
			if [ $ORI_RESOLUTION -gt 480 ];then
				if [ $RESOLUTION == "height" ];then
					TARGET_WIDTH="480"
					TARGET_HEIGHT="-1"
				else
					TARGET_WIDTH="-1"
					TARGET_HEIGHT="480"
				fi
			fi
			TARGET_QUALITY_MSG="标清-(480P-)"
			;;
		 sd|SD|480p|480P)
			if [ $ORI_RESOLUTION -gt 480 ];then
				if [ $RESOLUTION == "width" ];then
					TARGET_WIDTH="480"
					TARGET_HEIGHT="-1"
				else
					TARGET_WIDTH="-1"
					TARGET_HEIGHT="480"
				fi
			fi
			TARGET_QUALITY_MSG="标清(480P)"
			;;
		 hd-|HD-|720p-|720P-)
			if [ $ORI_RESOLUTION -gt 720 ];then
				if [ $RESOLUTION == "height" ];then
					TARGET_WIDTH="720"
					TARGET_HEIGHT="-1"
				else
					TARGET_WIDTH="-1"
					TARGET_HEIGHT="720"
				fi
			fi
			TARGET_QUALITY_MSG="高清-(720P-)"
			;;
		 hd|HD|720p|720P)
			if [ $ORI_RESOLUTION -gt 720 ];then
				if [ $RESOLUTION == "width" ];then
					TARGET_WIDTH="720"
					TARGET_HEIGHT="-1"
				else
					TARGET_WIDTH="-1"
					TARGET_HEIGHT="720"
				fi
			fi
			TARGET_QUALITY_MSG="高清(720P)"
			;;
		 uhd-|UHD-|1080p-|1080P-)
			if [ $ORI_RESOLUTION -gt 1080 ];then
				if [ $RESOLUTION == "height" ];then
					TARGET_WIDTH="1080"
					TARGET_HEIGHT="-1"
				else
					TARGET_WIDTH="-1"
					TARGET_HEIGHT="1080"
				fi
			fi
			TARGET_QUALITY_MSG="超清-(1080P-)"
			;;
		 uhd|UHD|1080p|1080P)
			if [ $ORI_RESOLUTION -gt 1080 ];then
				if [ $RESOLUTION == "width" ];then
					TARGET_WIDTH="1080"
					TARGET_HEIGHT="-1"
				else
					TARGET_WIDTH="-1"
					TARGET_HEIGHT="1080"
				fi
			fi
			TARGET_QUALITY_MSG="超清(1080P)"
			;;
		 *)
			TARGET_WIDTH=$ORI_WIDTH
			TARGET_HEIGHT=$ORI_HEIGHT
			;;
		esac
	else
		TARGET_QUALITY_MSG="未指定"
	fi

	if [ "$TARGET_FRAMERATE" == "disable" ];then
		TARGET_FRAMERATE="$ORI_FRAMWRATE"
	fi

	if [ "$TARGET_CODEC" != "libx264" ] || [ "$TARGET_CODEC" != "libx265" ];then
		TARGET_CODEC="libx264"
	fi

	cut1=$(ffmpeg -i "$filename" 2>&1 | grep 'bitrate')
	cut2=${cut1#*bitrate: }
	cutres=${cut2% *}
	cutfile="${filename##*/}"
	output="$filedir/$OUT_DIR/${cutfile%.*}.${OUTPUT_FORMAT}"
	input="${filename}"
	bitrate=${TARGET_BITRATE}
	if [[ $cutres -gt $TARGET_BITRATE ]];then
		if [[ $cutres -gt $[$TARGET_BITRATE*2] ]];then
			if [[ $cutres -gt $[$TARGET_BITRATE*2+1000] ]];then
			bitrate="$[$TARGET_BITRATE+500]"
			else
			bitrate="$[$cutres/2]"
			fi
		fi
	fi

	echo
	echo "当前工作路径: $filedir"
	echo "第$TASK_COUNT个视频处理任务"
	echo "输入文件名: ${filename##*/}"
	echo "输出文件名: ${cutfile%.*}.${OUTPUT_FORMAT}"
	echo "输出位置: ${filedir}/${OUT_DIR}"
	echo "视频码率: ${cutres}k"
	echo "视频帧率: ${TARGET_FRAMERATE}fps"
	echo "缩放比例: ${TARGET_ZOOM_RATIO_MSG}"
	echo "画质: ${TARGET_QUALITY_MSG}"
	echo "编码器: ${TARGET_CODEC}"
	if [[ $cutres -gt $TARGET_BITRATE ]];then
		echo "大于${TARGET_BITRATE}k, 开始压缩视频..."
		echo "码率: ${cutres}k -> ${bitrate}k"
		echo "${filename##*/}: ${cutres}k -> ${bitrate}k; Framerate: ${ORI_FRAMWRATE} -> ${TARGET_FRAMERATE}; Zoom: ${TARGET_ZOOM_RATIO_MSG}; Quality: ${TARGET_QUALITY_MSG}" >> "$filedir/${OUT_DIR}/$LOG_NAME"
		ffpb -i "$input" -b:v ${bitrate}k -r ${TARGET_FRAMERATE} -vf "scale=${TARGET_WIDTH}:${TARGET_HEIGHT}" -c:v ${TARGET_CODEC} -preset ${TARGET_CODEC_PRESET} "$output"
	else
		echo "低于${TARGET_BITRATE}k, 无需压缩, 默认跳过..."
		echo "${filename##*/}: ${cutres}k (已跳过)" >> "$filedir/${OUT_DIR}/$LOG_NAME"
	fi
	cd "$WORKDIR"
}

function tmpInit(){
	if [ ! -f $TMP1 ];then
		touch $TMP1
	fi
}

function tmpClean(){
	if [ -f $TMP1 ];then
		rm $TMP1
	fi
}

### exec function ###
loadConf

if [ ! -z $1 ];then
	if [ $1 = "genconf" ];then
		echo "compress_video_enhanced: 仅生成配置文件(genconf)"
		exit 0
	fi
fi

WORKDIR=$PWD
TASK_COUNT=0
TMP1="toolbox_image_tmp1"

tmpClean
tmpInit

INPUT_FORMAT_ARR=(`echo $INPUT_FORMAT | sed 's/ //g' | tr '|' ' '`)

### find target video path ###
OLDIFS=$IFS
IFS="|"
for format in ${INPUT_FORMAT_ARR[@]}
do
	if [[ "$(find $PWD -name "*.$format")" ]];then
		find $PWD -name "*.$format" | while read -r line
		do
			echo -n "${line}|" >> $TMP1
		done
	fi
done

FILE_LIST="$(cat $TMP1)"
FILE_LIST="${FILE_LIST%|*}"

### begin compress video ###
for filename in $FILE_LIST
do
	compressVideo "$filename"
done
echo

tmpClean

IFS=$OLDIFS
