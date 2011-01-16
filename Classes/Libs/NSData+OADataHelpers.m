#import "NSData+OADataHelpers.h"

@implementation NSData (OADataHelpers)

- (NSString*) UTF8String
{
  return [[[NSString alloc] initWithData:[self dataByHealingUTF8Stream] encoding:NSUTF8StringEncoding] autorelease];
}

// Replaces all broken sequences by � character and returns NSData with valid UTF-8 bytes.
- (NSData*) dataByHealingUTF8Stream
{
  //  bits
  //  7   	U+007F      0xxxxxxx
  //  11   	U+07FF      110xxxxx	10xxxxxx
  //  16  	U+FFFF      1110xxxx	10xxxxxx	10xxxxxx
  //  21  	U+1FFFFF    11110xxx	10xxxxxx	10xxxxxx	10xxxxxx
  //  26  	U+3FFFFFF   111110xx	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx
  //  31  	U+7FFFFFFF  1111110x	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx
  
  #define b00000000 0x00
  #define b10000000 0x80
  #define b11000000 0xc0
  #define b11100000 0xe0
  #define b11110000 0xf0
  #define b11111000 0xf8
  #define b11111100 0xfc
  #define b11111110 0xfe
  
  static NSString* replacementCharacter = @"�";
  NSData* replacementCharacterData = [replacementCharacter dataUsingEncoding:NSUTF8StringEncoding];
  
  NSMutableData* resultData = [NSMutableData dataWithCapacity:[self length]];
  const char *bytes = [self bytes];
  NSUInteger length = [self length];
  
  static const NSUInteger bufferMaxSize = 1024;
  char buffer[bufferMaxSize]; // not initialized, but will be filled in completely before copying to resultData
  NSUInteger bufferIndex = 0;
  
  #define FlushBuffer() if (bufferIndex > 0) { \
    [resultData appendBytes:buffer length:bufferIndex]; \
    bufferIndex = 0; \
  }
  #define CheckBuffer() if ((bufferIndex+5) >= bufferMaxSize) { \
    [resultData appendBytes:buffer length:bufferIndex]; \
    bufferIndex = 0; \
  }
  
  NSUInteger byteIndex = 0;
  BOOL invalidByte = NO;
  while (byteIndex < length)
  {
    char byte = bytes[byteIndex];
    
    if ((byte & b10000000) == b00000000) // 0xxxxxxx
    {
      CheckBuffer();
      buffer[bufferIndex++] = byte;
    }
    else if ((byte & b11100000) == b11000000) // 110xxxxx 10xxxxxx
    {
      if (byteIndex+1 >= length) {
        FlushBuffer();
        return resultData;
      }
      char byte2 = bytes[++byteIndex];
      if ((byte2 & b11000000) == b10000000)
      {
        CheckBuffer();
        buffer[bufferIndex++] = byte;
        buffer[bufferIndex++] = byte2;
      }
      else
      {
        invalidByte = YES;
      }
    }
    else if ((byte & b11110000) == b11100000) // 1110xxxx 10xxxxxx 10xxxxxx
    {
      if (byteIndex+2 >= length) {
        FlushBuffer();
        return resultData;
      }
      char byte2 = bytes[++byteIndex];
      char byte3 = bytes[++byteIndex];
      if ((byte2 & b11000000) == b10000000 && 
          (byte3 & b11000000) == b10000000)
      {
        CheckBuffer();
        buffer[bufferIndex++] = byte;
        buffer[bufferIndex++] = byte2;
        buffer[bufferIndex++] = byte3;
      }
      else
      {
        invalidByte = YES;
      }
    }
    else if ((byte & b11111000) == b11110000) // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
    {
      if (byteIndex+3 >= length) {
        FlushBuffer();
        return resultData;
      }
      char byte2 = bytes[++byteIndex];
      char byte3 = bytes[++byteIndex];
      char byte4 = bytes[++byteIndex];
      if ((byte2 & b11000000) == b10000000 && 
          (byte3 & b11000000) == b10000000 && 
          (byte4 & b11000000) == b10000000)
      {
        CheckBuffer();
        buffer[bufferIndex++] = byte;
        buffer[bufferIndex++] = byte2;
        buffer[bufferIndex++] = byte3;
        buffer[bufferIndex++] = byte4;
      }
      else
      {
        invalidByte = YES;
      }
    }
    else if ((byte & b11111100) == b11111000) // 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
    {
      if (byteIndex+4 >= length) {
        FlushBuffer();
        return resultData;
      }
      char byte2 = bytes[++byteIndex];
      char byte3 = bytes[++byteIndex];
      char byte4 = bytes[++byteIndex];
      char byte5 = bytes[++byteIndex];
      if ((byte2 & b11000000) == b10000000 && 
          (byte3 & b11000000) == b10000000 && 
          (byte4 & b11000000) == b10000000 && 
          (byte5 & b11000000) == b10000000)
      {
        CheckBuffer();
        buffer[bufferIndex++] = byte;
        buffer[bufferIndex++] = byte2;
        buffer[bufferIndex++] = byte3;
        buffer[bufferIndex++] = byte4;
        buffer[bufferIndex++] = byte5;
      }
      else
      {
        invalidByte = YES;
      }
    }
    else if ((byte & b11111110) == b11111100) // 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
    {
      if (byteIndex+5 >= length) {
        FlushBuffer();
        return resultData;
      }
      char byte2 = bytes[++byteIndex];
      char byte3 = bytes[++byteIndex];
      char byte4 = bytes[++byteIndex];
      char byte5 = bytes[++byteIndex];
      char byte6 = bytes[++byteIndex];
      if ((byte2 & b11000000) == b10000000 && 
          (byte3 & b11000000) == b10000000 && 
          (byte4 & b11000000) == b10000000 && 
          (byte5 & b11000000) == b10000000 &&
          (byte6 & b11000000) == b10000000)
      {
        CheckBuffer();
        buffer[bufferIndex++] = byte;
        buffer[bufferIndex++] = byte2;
        buffer[bufferIndex++] = byte3;
        buffer[bufferIndex++] = byte4;
        buffer[bufferIndex++] = byte5;
        buffer[bufferIndex++] = byte6;
      }
      else
      {
        invalidByte = YES;
      }
    }
    else
    {
      invalidByte = YES;
    }
    
    if (invalidByte)
    {
      invalidByte = NO;
      FlushBuffer();
      [resultData appendData:replacementCharacterData];
    }
    
    byteIndex++;
  }
  FlushBuffer();
  return resultData;
}

@end
