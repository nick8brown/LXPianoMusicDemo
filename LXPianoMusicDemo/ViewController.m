//
//  ViewController.m
//  LXPianoMusicDemo
//
//  Created by LX Zeng on 2018/12/4.
//  Copyright © 2018   https://github.com/nick8brown   All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define MusicName @"piano.m4a"

@interface ViewController ()

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, copy) NSString *filePath;

@end

@implementation ViewController

#pragma mark - lazy load
- (NSFileManager *)fileManager {
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

- (NSString *)filePath {
    if (!_filePath) {
        _filePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        NSString *fileName = [_filePath stringByAppendingPathComponent:@"PianoMusic"];
        BOOL isCreateSuccess = [self.fileManager createDirectoryAtPath:fileName withIntermediateDirectories:YES attributes:nil error:nil];
        _filePath = (isCreateSuccess) ? [fileName stringByAppendingPathComponent:MusicName] : @"";
    }
    return _filePath;
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - 25个音符随机合成
- (IBAction)soundBtnClick:(UIButton *)sender {
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    NSMutableArray *pathArray = [NSMutableArray array];
    NSMutableArray *audioAssetArray = [NSMutableArray array];
    NSMutableArray *audioTrackArray = [NSMutableArray array];
    NSMutableArray *audioAssetTrackArray = [NSMutableArray array];
    
    for (int i = 1; i <= 25; i++) {
        NSInteger index = arc4random()%25 + 1;
        NSLog(@"================%zd", index);
        
        NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%zd", index] ofType:@"mp3"];
        AVURLAsset *audioAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
        AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        
        [pathArray addObject:path];
        [audioAssetArray addObject:audioAsset];
        [audioTrackArray addObject:audioTrack];
        [audioAssetTrackArray addObject:audioAssetTrack];
    }
    
    
    for (int i = 0; i < audioTrackArray.count; i++) {
        AVURLAsset *audioAsset = audioAssetArray[i];
        AVMutableCompositionTrack *audioTrack = audioTrackArray[i];
        AVAssetTrack *audioAssetTrack = audioAssetTrackArray[i];
        
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:audioAssetTrack atTime:((i == 0) ? kCMTimeZero : audioAsset.duration) error:nil];
    }
    
    
    
    // 合并后的文件导出 - `presetName`要和之后的`session.outputFileType`相对应。
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    NSString *outPutFilePath = [[self.filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:MusicName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPutFilePath error:nil];
    }
    
    // 查看当前session支持的fileType类型
    NSLog(@"---%@",[session supportedFileTypes]);
    
    session.outputURL = [NSURL fileURLWithPath:outPutFilePath];
    session.outputFileType = AVFileTypeAppleM4A; //与上述的`present`相对应
    session.shouldOptimizeForNetworkUse = YES;   //优化网络
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"合并成功----%@", outPutFilePath);
            
            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:outPutFilePath] error:nil];
            [self.audioPlayer play];
        } else {
            // 其他情况, 具体请看这里`AVAssetExportSessionStatus`.
        }
    }];
}

@end
