#!/bin/bash

COMMAND=$1
shift

MODE=""
SOURCE=""
RTMP_URL=""

# 解析选项
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)
      MODE="file"
      SOURCE="$2"
      shift 2
      ;;
    -s|--stream)
      MODE="stream"
      SOURCE="$2"
      shift 2
      ;;
    -u|--url)
      RTMP_URL="$2"
      shift 2
      ;;
    *)
      echo "❌ 未知参数: $1"
      exit 1
      ;;
  esac
done

PID_FILE="/tmp/stream_$(echo "$SOURCE" | md5sum | cut -d' ' -f1).pid"

start_stream() {
  if [ "$MODE" = "file" ]; then
    if [ ! -f "$SOURCE" ]; then
      echo "❌ 视频文件不存在: $SOURCE"
      exit 1
    fi
    INPUT_OPTS="-stream_loop -1 -re -i \"$SOURCE\""
  elif [ "$MODE" = "stream" ]; then
    INPUT_OPTS="-re -i \"$SOURCE\""
  else
    echo "❌ 未指定输入类型，请使用 -f 或 -s"
    exit 1
  fi

  if [ -z "$RTMP_URL" ]; then
    echo "❌ 未指定推送地址，请使用 -u"
    exit 1
  fi

  echo "🎬 启动推流: $SOURCE → $RTMP_URL"
  nohup bash -c "ffmpeg $INPUT_OPTS -c copy -f flv \"$RTMP_URL\"" > /dev/null 2>&1 &
  echo $! > "$PID_FILE"
  echo "✅ FFmpeg 已在后台运行，PID: $(cat $PID_FILE)"
}

stop_stream() {
  if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    echo "🛑 停止 FFmpeg，PID: $PID"
    kill "$PID" && rm -f "$PID_FILE"
  else
    echo "⚠️ 没有找到 PID 文件，可能 FFmpeg 没在运行"
  fi
}

case "$COMMAND" in
  start)
    start_stream
    ;;
  stop)
    stop_stream
    ;;
  *)
    echo "用法:"
    echo "  $0 start -f <video_file> -u <rtmp_url>"
    echo "  $0 start -s <input_url> -u <rtmp_url>"
    echo "  $0 stop -f <video_file>"
    echo "  $0 stop -s <input_url>"
    ;;
esac
