const WebSocket = require('ws');
const fs = require('fs');

const API_KEY = "sk-103ddf012c494f5099a10ec41f171253";
const WS_URL = "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime";
const AUDIO_FILE = "C:\\Users\\Mayn\\Downloads\\backup_1779071705220\\recording_1779071025849.wav";

function generateTaskId() {
    return Array.from({length: 32}, () => Math.floor(Math.random() * 16).toString(16)).join('');
}

function readWavFile(filePath) {
    const buffer = fs.readFileSync(filePath);
    // WAV header is 44 bytes
    const audioData = buffer.slice(44);
    console.log(`  音频数据大小: ${audioData.length} bytes`);
    return audioData;
}

async function testWebSocket() {
    console.log("=".repeat(60));
    console.log("Qwen WebSocket 实时转写测试 (正确协议)");
    console.log("=".repeat(60));
    
    // 读取音频文件
    console.log(`\n读取音频文件: ${AUDIO_FILE}`);
    const audioData = readWavFile(AUDIO_FILE);
    
    // 连接 WebSocket
    console.log(`\n连接 WebSocket: ${WS_URL}`);
    
    const ws = new WebSocket(WS_URL, {
        headers: {
            "Authorization": `Bearer ${API_KEY}`
        }
    });
    
    return new Promise((resolve, reject) => {
        let taskStarted = false;
        let transcript = "";
        const taskId = generateTaskId();
        
        ws.on('open', () => {
            console.log("  WebSocket 连接成功!");
            
            // 发送 run-task 指令
            const runTask = {
                header: {
                    action: "run-task",
                    task_id: taskId,
                    streaming: "duplex"
                },
                payload: {
                    task_group: "audio",
                    task: "asr",
                    function: "recognition",
                    model: "qwen3-asr-flash-realtime",
                    parameters: {
                        sample_rate: 16000,
                        format: "pcm"
                    },
                    input: {}
                }
            };
            console.log("\n发送 run-task 指令...");
            console.log(JSON.stringify(runTask, null, 2));
            ws.send(JSON.stringify(runTask));
        });
        
        ws.on('message', (data) => {
            const message = JSON.parse(data.toString());
            console.log(`\n  收到事件: ${message.header?.event || message.type}`);
            console.log(JSON.stringify(message, null, 2).substring(0, 500));
            
            const event = message.header?.event;
            
            if (event === 'task-started') {
                console.log("  ✓ task-started 收到，开始发送音频...");
                taskStarted = true;
                
                // 发送音频数据（原始 PCM 字节）
                const chunkSize = 640; // 20ms @ 16kHz 16bit mono
                const totalChunks = Math.floor(audioData.length / chunkSize);
                console.log(`  总块数: ${totalChunks}`);
                
                let chunkIndex = 0;
                const sendInterval = setInterval(() => {
                    if (chunkIndex >= totalChunks) {
                        clearInterval(sendInterval);
                        console.log("  ✓ 音频数据发送完成");
                        
                        // 发送 finish-task 指令
                        const finishTask = {
                            header: {
                                action: "finish-task",
                                task_id: taskId,
                                streaming: "duplex"
                            },
                            payload: {
                                input: {}
                            }
                        };
                        console.log("\n发送 finish-task 指令...");
                        ws.send(JSON.stringify(finishTask));
                        return;
                    }
                    
                    const start = chunkIndex * chunkSize;
                    const end = Math.min(start + chunkSize, audioData.length);
                    const chunk = audioData.slice(start, end);
                    
                    // 直接发送原始 PCM 字节
                    ws.send(chunk);
                    
                    if (chunkIndex < 5 || chunkIndex % 50 === 0) {
                        console.log(`  发送块 ${chunkIndex + 1}/${totalChunks}, 大小: ${chunk.length} bytes`);
                    }
                    
                    chunkIndex++;
                }, 20); // 每20ms发送一块
                
            } else if (event === 'result-generated') {
                const sentence = message.payload?.output?.sentence;
                if (sentence) {
                    const text = sentence.text || '';
                    const isFinal = sentence.sentence_end || false;
                    transcript += text;
                    console.log(`  📝 转写结果: ${text} (sentence_end: ${isFinal})`);
                }
                
            } else if (event === 'task-finished') {
                console.log("  ✓ 任务完成");
                ws.close();
                resolve(transcript);
                
            } else if (event === 'task-failed') {
                const errorMsg = message.header?.error_message || '未知错误';
                console.log(`  ❌ 任务失败: ${errorMsg}`);
                ws.close();
                reject(new Error(errorMsg));
                
            } else {
                console.log(`  其他事件: ${JSON.stringify(message).substring(0, 200)}`);
            }
        });
        
        ws.on('error', (error) => {
            console.error("  ❌ WebSocket 错误:", error.message);
            reject(error);
        });
        
        ws.on('close', () => {
            console.log("\n  WebSocket 连接关闭");
            if (!taskStarted) {
                reject(new Error('Connection closed before task started'));
            }
        });
        
        // 超时处理
        setTimeout(() => {
            if (!taskStarted) {
                ws.close();
                reject(new Error('Timeout waiting for task-started'));
            }
        }, 30000);
    });
}

testWebSocket()
    .then((transcript) => {
        console.log("\n" + "=".repeat(60));
        console.log("测试完成");
        console.log("最终转写结果:", transcript);
        console.log("=".repeat(60));
        process.exit(0);
    })
    .catch((error) => {
        console.error("\n" + "=".repeat(60));
        console.error("测试失败:", error.message);
        console.error("=".repeat(60));
        process.exit(1);
    });
