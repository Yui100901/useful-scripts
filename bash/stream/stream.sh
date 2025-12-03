#!/bin/bash

COMMAND=$1
shift

MODE=""
SOURCE=""
STREAM_KEY=""
RTMP_BASE="rtmp://127.0.0.1/live"

# 解析参数
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
    -k|--key)
      STREAM_KEY="$2"
      shift 2
      ;;
    *)
      echo "❌ 未知参数: $1"
      exit 1
      ;;
  esac
done

# 校验输入
if [ -z "$SOURCE" ]; then
  echo "❌ 未指定输入源，请使用 -f 或 -s"
  exit 1
fi

# 自动生成 stream key
if [ -z "$STREAM_KEY" ]; then
  if [ "$MODE" = "file" ]; then
    STREAM_KEY=$(basename "$SOURCE")
    STREAM_KEY="${STREAM_KEY%.*}"  # 去掉扩展名
  else
    STREAM_KEY=$(date +%s | md5sum | cut -c1-8)
  fi
fi

RTMP_URL="$RTMP_BASE/$STREAM_KEY"
PID_FILE="/tmp/stream_$STREAM_KEY.pid"

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

  echo "🎬 启动推流: $SOURCE → $RTMP_URL"
  nohup bash -c "ffmpeg $INPUT_OPTS -c copy -f flv \"$RTMP_URL\"" > /dev/null 2>&1 &
  echo $! > "$PID_FILE"
  echo "✅ FFmpeg 已在后台运行，PID: $(cat $PID_FILE)"
  echo "📺 推流地址: $RTMP_URL"
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
    echo "  $0 start -f <video_file> [-k <stream_key>]"
    echo "  $0 start -s <input_url> [-k <stream_key>]"
    echo "  $0 stop -f <video_file>"
    echo "  $0 stop -s <input_url>"
    ;;
esac
