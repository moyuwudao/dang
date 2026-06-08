export type TestableFeature = 'textAnalysis' | 'speechTranscribe' | 'speechRealtime' | 'speechOffline' | 'imageRecognition';
export declare class TestApiKeyDto {
    feature?: TestableFeature | 'connectivity';
    testText?: string;
    testAudioUrl?: string;
    testImageUrl?: string;
}
