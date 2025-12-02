#!/bin/bash

COMMAND="$1"
VIDEO="${2:-test.mp4}"
STREAM_KEY="${VIDEO%.*}"
RTMP_URL="${3:-rtmp://127.0.0.1/live/$STREAM_KEY}"
PID_FILE="/tmp/ffmpeg_${STREAM_KEY}.pid"

start_stream() {
  if [ ! -f "$VIDEO" ]; then
    echo "❌ 视频文件不存在: $VIDEO"
    exit 1
  fi

  echo "🎬 启动推流: $VIDEO → $RTMP_URL"
  nohup ffmpeg -stream_loop -1 -re -i "$VIDEO" \
    -c copy -f flv "$RTMP_URL" > /dev/null 2>&1 &
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
    echo "  $0 start [video_file] [rtmp_url]"
    echo "  $0 stop [video_file]"
    echo "示例:"
    echo "  $0 start test.mp4 rtmp://127.0.0.1/live/test"
    echo "  $0 stop test.mp4"
    ;;
esac
