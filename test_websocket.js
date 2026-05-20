const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

const API_KEY = "sk-103ddf012c494f5099a10ec41f171253";
const WS_URL = "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen-omni-turbo-realtime";
const AUDIO_FILE = "C:\\Users\\Mayn\\Downloads\\backup_1779071705220\\recording_1779071025849.wav";

function readWavFile(filePath) {
    const buffer = fs.readFileSync(filePath);
    // WAV header is 44 bytes
    const audioData = buffer.slice(44);
    console.log(`  音频数据大小: ${audioData.length} bytes`);
    return audioData;
}

async function testWebSocket() {
    console.log("=".repeat(60));
    console.log("Qwen WebSocket 实时转写测试 (Node.js)");
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
        let sessionCreated = false;
        let sessionUpdated = false;
        let audioSent = false;
        let transcript = "";
        
        ws.on('open', () => {
            console.log("  WebSocket 连接成功!");
        });
        
        ws.on('message', (data) => {
            const message = JSON.parse(data.toString());
            console.log(`  收到事件: ${message.type}`);
            
            if (message.type === 'session.created') {
                console.log("  ✓ session.created 收到");
                sessionCreated = true;
                
                // 发送 session.update
                const sessionUpdate = {
                    event_id: `event_${Date.now()}_update`,
                    type: "session.update",
                    session: {
                        modalities: ["text"],
                        input_audio_format: "pcm",
                    }
                };
                console.log("\n发送 session.update...");
                ws.send(JSON.stringify(sessionUpdate));
                
            } else if (message.type === 'session.updated') {
                console.log("  ✓ session.updated 收到");
                sessionUpdated = true;
                
                // 发送 conversation.item.create
                const conversationItem = {
                    event_id: `event_${Date.now()}_item`,
                    type: "conversation.item.create",
                    item: {
                        type: "message",
                        role: "user",
                        content: [
                            {
                                type: "input_audio",
                                audio: "",
                            }
                        ]
                    }
                };
                console.log("\n发送 conversation.item.create...");
                ws.send(JSON.stringify(conversationItem));
                
                // 发送 response.create
                const responseCreate = {
                    event_id: `event_${Date.now()}_response`,
                    type: "response.create",
                    response: {
                        modalities: ["text"],
                    }
                };
                console.log("发送 response.create...");
                ws.send(JSON.stringify(responseCreate));
                
                // 发送音频数据
                console.log("\n发送音频数据...");
                const chunkSize = 640; // 20ms @ 16kHz 16bit mono
                const totalChunks = Math.floor(audioData.length / chunkSize);
                console.log(`  总块数: ${totalChunks}`);
                
                let chunkIndex = 0;
                const sendInterval = setInterval(() => {
                    if (chunkIndex >= totalChunks) {
                        clearInterval(sendInterval);
                        console.log("  ✓ 音频数据发送完成");
                        
                        // 发送 commit
                        const commitMessage = {
                            event_id: `event_${Date.now()}_commit`,
                            type: "input_audio_buffer.commit"
                        };
                        console.log("\n发送 input_audio_buffer.commit...");
                        ws.send(JSON.stringify(commitMessage));
                        audioSent = true;
                        return;
                    }
                    
                    const start = chunkIndex * chunkSize;
                    const end = Math.min(start + chunkSize, audioData.length);
                    let chunk = audioData.slice(start, end);
                    
                    if (chunk.length < chunkSize) {
                        const padding = Buffer.alloc(chunkSize - chunk.length);
                        chunk = Buffer.concat([chunk, padding]);
                    }
                    
                    const appendMessage = {
                        event_id: `event_${Date.now()}_audio`,
                        type: "input_audio_buffer.append",
                        audio: chunk.toString('base64')
                    };
                    ws.send(JSON.stringify(appendMessage));
                    
                    if (chunkIndex < 5 || chunkIndex % 50 === 0) {
                        console.log(`  发送块 ${chunkIndex + 1}/${totalChunks}, 大小: ${chunk.length} bytes`);
                    }
                    
                    chunkIndex++;
                }, 20); // 每20ms发送一块
                
            } else if (message.type === 'error') {
                console.log(`  ❌ 错误: ${JSON.stringify(message.error)}`);
                ws.close();
                reject(new Error(message.error?.message || 'Unknown error'));
                
            } else if (message.type === 'response.audio_transcript.delta') {
                const delta = message.delta || '';
                transcript += delta;
                console.log(`  📝 转写增量: ${delta}`);
                
            } else if (message.type === 'response.audio_transcript.done') {
                console.log(`  ✅ 转写完成: ${message.transcript || transcript}`);
                ws.close();
                resolve(transcript);
                
            } else if (message.type === 'response.done') {
                console.log("  ✓ 响应完成");
                ws.close();
                resolve(transcript);
                
            } else if (message.type === 'input_audio_buffer.speech_started') {
                console.log("  🎤 检测到语音开始");
                
            } else if (message.type === 'input_audio_buffer.speech_stopped') {
                console.log("  🎤 检测到语音结束");
                
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
            if (!audioSent) {
                reject(new Error('Connection closed before audio was sent'));
            }
        });
        
        // 超时处理
        setTimeout(() => {
            if (!sessionCreated) {
                ws.close();
                reject(new Error('Timeout waiting for session.created'));
            }
        }, 10000);
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
