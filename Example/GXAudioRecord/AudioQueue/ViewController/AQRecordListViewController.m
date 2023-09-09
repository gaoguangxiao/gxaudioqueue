//
//  AQRecordListViewController.m
//  recordAudip
//
//  Created by 高广校 on 2023/8/25.
//

#import "AQRecordListViewController.h"
#import <Masonry/Masonry.h>
#import "AudioQueueCell.h"
#import "GGXFileManeger.h"
@interface AQRecordListViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;//展示录音文件

@property (nonatomic, strong) NSMutableArray *dataArray;
@end

@implementation AQRecordListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //录制文件列表
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view);
        make.left.bottom.right.mas_equalTo(0);
    }];
    
    [self reloadRecordList];
}

- (void)reloadRecordList {

    NSArray *data = [GGXFileManeger.shared getPlistData];

    [self.dataArray removeAllObjects];
    [self.dataArray addObjectsFromArray:data];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    AudioQueueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AudioQueueCell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[AudioQueueCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    NSDictionary *uuidKey = [self.dataArray objectAtIndex:indexPath.row];
    NSString *peripheralName = uuidKey[@"name"];
//    cell.textLabel.text = [NSString stringWithFormat:@"%@",peripheralName];
    [cell fillData:peripheralName];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //播放
    NSDictionary *uuidKey = [self.dataArray objectAtIndex:indexPath.row];
    NSString *peripheralName = uuidKey[@"name"];
    NSLog(@"%@",peripheralName);
    NSString *filePath = [GGXFileManeger.shared getFilePath:peripheralName];
//    [self.playerManager startPlay:filePath];
//    NSString *documentDicPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
//    NSString *dictionaryName = [documentDicPath stringByAppendingPathComponent:kAudioFileName];
//    [JHAudioRecorder.shareAudioRecorder playRecordingWith:];
}

- (NSMutableArray *)dataArray
{
    if ( !_dataArray ) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return _dataArray;
}

- (UITableView *)tableView {
    if (!_tableView) {
        CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        _tableView.contentInset = UIEdgeInsetsMake(5, 0, 0, 0);
        
        _tableView.scrollIndicatorInsets = self.tableView.contentInset;
        [_tableView registerNib:[UINib nibWithNibName:@"AudioQueueCell" bundle:nil] forCellReuseIdentifier:@"AudioQueueCell"];
//        [_tableView registerClass:[AudioQueueCell class] forCellReuseIdentifier:@"AudioQueueCell"];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
//        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 150;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = nil;
    }
    return _tableView;
}
@end
