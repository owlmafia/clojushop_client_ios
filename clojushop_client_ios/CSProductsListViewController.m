//
//  CSProductsListViewController.m
//  clojushop_client
//
//  Created by ischuetz on 16/04/2014.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

#import "CSProductsListViewController.h"
#import "AFHTTPRequestOperation.h"
#import "AFHTTPRequestOperationManager.h"
#import "CSProduct.h"
#import "CSProduct.h"
#import "CSProductCell.h"
#import "CSProductDetailsViewController.h"
#import "CSDataProvider.h"


@interface CSProductsListViewController ()

@end

@implementation CSProductsListViewController {
    NSArray *products;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Clojushop client";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINib *productCellNib = [UINib nibWithNibName:@"CSProductCell" bundle:nil];
    
    [[self tableView] registerNib:productCellNib forCellReuseIdentifier:@"CSProductCell"];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];

    [self requestProducts];
}

- (void)requestProducts {
    
    [self setProgressHidden: NO];
    
    [[CSDataProvider sharedDataProvider] getProducts:0 size:4 successHandler:^(NSArray *products) {
        [self onRetrievedProducts: products];
        
        [self setProgressHidden: YES];
        
        
    } failureHandler:^{
    }];
}
  
- (void)onRetrievedProducts:(NSArray *)prods {
    products = prods;
    [[self tableView] reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   return [products count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CSProductCell";
    CSProductCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    CSProduct *product = [products objectAtIndex:[indexPath row]];
    
    [[cell productName] setText:[product name]];
    [[cell productDescr] setText:[product descr]];
    [[cell productBrand] setText:[product seller]];
    [[cell productPrice] setText:[product price]];
    
    NSURL *imageUrl = [NSURL URLWithString:[product imgList]];
    NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    [[cell productImg] setImage:image];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 133;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CSProduct *product = [products objectAtIndex:[indexPath row]];
    
    CSProductDetailsViewController *detailViewController = [[CSProductDetailsViewController alloc] initWithNibName:@"CSProductDetailsViewController" bundle:nil];

    [detailViewController setProduct: product];
        
    [self.navigationController pushViewController:detailViewController animated:YES];
}

@end
