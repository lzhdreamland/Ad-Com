//
//  ServiceConnector.m
//  workWithServerTemplate
//
//  Created by ZihaoLin on 3/8/15.
//  Copyright (c) 2015 ZihaoLin. All rights reserved.
//

#import "ServiceConnector.h"

@implementation ServiceConnector{
  NSMutableData *receivedData;
}

- (void)loginFunUseUserName:(NSString *)username andPassword:(NSString *)password{
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://172.31.175.168:8888/webServerTest.php"]];
  
  [request setHTTPMethod:@"POST"];
  [request addValue:@"login" forHTTPHeaderField:@"METHOD"];
  
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  [dictionary setValue:username forKey:@"user_name"];
  [dictionary setValue:password forKey:@"user_password"];
  
  NSError *error;
  //serialize the dictionary data as json
  NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:kNilOptions error:&error];
  
  [request setHTTPBody:data]; //set the data as the post body
  [request addValue:[NSString stringWithFormat:@"%lu",(unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
  
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  if (!connection) {
    NSLog(@"Connect Failed");
  }
}

- (void)registerFunUserName:(NSString *)userName andPassword:(NSString *)password{
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://172.31.175.168:8888/webServerTest.php"]];
  NSError *error;
  
  [request setHTTPMethod:@"POST"];
  [request addValue:@"register" forHTTPHeaderField:@"METHOD"];
  
  //create data that will be sent in the post
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  [dictionary setValue:userName forKey:@"user_name"];
  [dictionary setValue:password forKey:@"user_password"];
  
  //serialize the dictionary data as json
  NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:kNilOptions error:&error];
  
  [request setHTTPBody:data]; //set the data as the post body
  [request addValue:[NSString stringWithFormat:@"%lu",(unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
  
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  if(!connection){
    NSLog(@"Connection Failed");
  }else{
    
    NSLog(@"Connection Success : %@,%@",[request HTTPMethod],[NSJSONSerialization JSONObjectWithData:[request HTTPBody] options:kNilOptions error:&error]);
  }
}

- (void)requestUserInfoWithUserName:(NSString *)user_name{
  NSLog(@"request user info from web service");
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://172.31.175.168:8888/webServerTest.php"]];
  
  [request setHTTPMethod:@"POST"];
  [request addValue:@"requestUserInfo" forHTTPHeaderField:@"METHOD"];
  
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  [dictionary setValue:user_name forKey:@"user_name"];
  
  NSError *error;
  //serialize the dictionary data as json
  NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:kNilOptions error:&error];
  
  [request setHTTPBody:data]; //set the data as the post body
  [request addValue:[NSString stringWithFormat:@"%lu",(unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
  
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  if (!connection) {
    NSLog(@"Connect Failed");
  }
  
}

- (void)uploadMessagesToCloud:(NSArray *)messages withMessageType:(NSString *)message_type{
  NSLog(@"upload messages to cloud");
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://172.31.175.168:8888/webServerTest.php"]];
  
  [request setHTTPMethod:@"POST"];
  [request addValue:@"uploadMessages" forHTTPHeaderField:@"METHOD"];
  
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
  [dictionary setValue:message_type forKey:@"message_type"];
  
  NSArray *array = [[NSArray alloc] initWithArray:messages copyItems:YES];
  [dictionary setValue:array forKey:@"messages_array"];
  
  NSError *error;
  NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:kNilOptions error:&error];
  
  [request setHTTPBody:data];
  [request addValue:[NSString stringWithFormat:@"%lu",(unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
  
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  if (!connection) {
    NSLog(@"Connect Failed");
  }
}

- (void)downloadMessagesFromCloudDbWithUserName:(NSString *)user_name{
  NSLog(@"download messages from cloud");
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://172.31.175.168:8888/webServerTest.php"]];
  
  [request setHTTPMethod:@"POST"];
  [request addValue:@"downloadMessages" forHTTPHeaderField:@"METHOD"];
  
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
  [dictionary setValue:user_name forKey:@"user_name"];
  
  NSError *error;
  NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:kNilOptions error:&error];
  
  [request setHTTPBody:data];
  [request addValue:[NSString stringWithFormat:@"%lu",(unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
  
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  if (!connection) {
    NSLog(@"Connect Failed");
  }

}

#pragma mark - NSURLConnectionDataDelegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
  NSError *error;
  receivedData = [[NSMutableData alloc] initWithData:data];
  NSLog(@"receivedData is : %@",[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error]);
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
  
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
  NSLog(@"Connection failed with error: %@",error.localizedDescription);

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
  NSLog(@"Request Complete,recieved %lu bytes of data",(unsigned long)receivedData.length);
  
  //parsing data check functionalities : @"login" or @"register"
  NSError *error;
  
  if (receivedData.length == 0)
  {
    NSLog(@"parameter is nil");
  }else
  {
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:receivedData options:kNilOptions error:&error];
    NSArray *array = [[dictionary objectForKey:@"send_messages"] mutableCopy];
    NSLog(@"dictionary : %@",array);
    
    if ([[dictionary objectForKey:@"function"] isEqualToString:@"login"])
    {
      [self.delegate requestReturnedDataToLogin:receivedData];
    }else if ([[dictionary objectForKey:@"function"] isEqualToString:@"register"])
    {
      [self.delegate requestReturnedDataToRegister:receivedData];
    }else if ([[dictionary objectForKey:@"function"] isEqualToString:@"requestUserInfo"])
    {
      [self.delegate requestReturnedDataToUpdateLocalDb:receivedData];
    }else if ([[dictionary objectForKey:@"function"] isEqualToString:@"upload_messages"]){
      [self.delegate requestReturnedDataToUploadMessages:receivedData];
    }else if([[dictionary objectForKey:@"function"] isEqualToString:@"download_messages"]){
      [self.delegate requestReturnedDataToDownloadMessages:receivedData];
    }
  }
  
}

@end
