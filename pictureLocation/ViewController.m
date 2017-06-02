#import "ViewController.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/PHAsset.h>
#import <CoreLocation/CoreLocation.h>



@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    //创建一个UIImagePickerController对象
    UIImagePickerController *ctrl = [[UIImagePickerController alloc] init];
    //设置类型
    ctrl.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //设置代理
    ctrl.delegate = self;
    
    //显示
    [self presentViewController:ctrl animated:YES completion:nil];

    
    
}


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    if(picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary){
       
        UIImage *image= [info objectForKey:UIImagePickerControllerOriginalImage];
        self.imageView.image = image;
        
        
        NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        
        
        /******************方法一:8.0-10.0***********************/
        PHFetchResult *result = [PHAsset fetchAssetsWithALAssetURLs:@[assetURL] options:nil];
        PHAsset *asset = result.count?result.firstObject:nil;
        
        /**根据经纬度反向地理编译出地址信息 */
        if (asset)[self getAddressWithLongitude:asset.location.coordinate.longitude latitude:asset.location.coordinate.latitude];
        
        
        
    
        /******************方法二:4.0-9.0,推荐使用方法一***********************/
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library assetForURL:assetURL
                 resultBlock:^(ALAsset *asset) {
                     NSDictionary* imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:asset.defaultRepresentation.metadata];
                     
                     //地理位置信息
                     NSDictionary *GPS = [imageMetadata objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
                     
                     /** 经纬度*/
                     NSString *Latitude = [GPS objectForKey:@"Latitude"];
                     NSString *Longitude = [GPS objectForKey:@"Longitude"];
                     
                     /**反向地理编译出地址信息 */
                     [self getAddressWithLongitude:Longitude.doubleValue latitude:Latitude.doubleValue];
                     
                     
                     
                 }
                failureBlock:^(NSError *error) {
                }];
    }
    
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}


/**根据经纬度反向地理编译出地址信息 */
- (void)getAddressWithLongitude:(double)longitude latitude:(double)latitude
{
    
    CLLocation *location = [[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
    
    // 获取当前所在的城市名
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    //根据经纬度反向地理编译出地址信息
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *array, NSError *error)
     {
         if (array.count > 0)
         {
             CLPlacemark *placemark = [array objectAtIndex:0];
             //获取城市
             NSDictionary *addressDictionary = placemark.addressDictionary;
             NSArray *address = [addressDictionary objectForKey:@"FormattedAddressLines"];
             NSString *addressStr = address.count?address.firstObject:@"";
             
             NSLog(@"address---%s",addressStr.UTF8String);
             
             self.label.text = addressStr;
             
         }
         else if (error == nil && [array count] == 0)
         {
             NSLog(@"No results were returned.");
         }
         else if (error != nil)
         {
             self.label.text = @"可能不是原图,无法获取地理位置";
         }
     }];
    
    
}

/** 字典输出中文*/
- (NSString *)descriptionWithdic:(NSDictionary *)dic
{
    NSMutableString *str = [NSMutableString string];
    
    [str appendString:@"{\n"];
    
    // 遍历字典的所有键值对
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [str appendFormat:@"\t%@ = %@,\n", key, obj];
    }];
    
    [str appendString:@"}"];
    
    // 查出最后一个,的范围
    NSRange range = [str rangeOfString:@"," options:NSBackwardsSearch];
    if (range.length != 0) {
        // 删掉最后一个,
        [str deleteCharactersInRange:range];
    }
    
    return str;
}


@end






