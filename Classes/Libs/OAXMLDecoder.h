// Oleg Andreev <oleganza@gmail.com>
// November 30, 2010
// Pierlis

/*
 This decoder builds a nice block-based API for the stream-based NSXMLParser.
 Basically, XPath ease of use meets performance of the stream-oriented parser.
 
 You start by creating OAXMLDecoder object and setting its xmlData property.
 Then you create an empty object which will start parsing. We call it a rootObject.
 And you send [decoder decodeWithObject:rootObject startSelector:@selector(decodeWithDecoder:)];
 
 In the decodeWithDecoder: method you have a reference to decoder and the code in a pattern-matching style:
 
	- (void) decodeWithDecoder:(OAXMLDecoder*)aDecoder
	{
		[decoder startElement:@"root" withBlock:^{
			[decoder startElement:@"child" withBlock:^{
				[decoder endElement:@"name" withBlock:^{
					self.name = self.currentString;
				}];
				[decoder endElement:@"age" withBlock:^{
					self.age = self.currentString;
				}];
			}];
			[decoder startElement:@"another_object" withBlock:^{
				AnotherObject* anObject = [[AnotherObject new] autorelease];
				[anObject decodeWithDecoder:aDecoder]; // similar to the current method
			}];
		}];
	}

 The block passed with startElement:withBlock: is called when the tag is first time found
 
 
 Q: How do I get a value from <name>Oleg</name>?
 A: [decoder endElement:@"name" withBlock:^{ self.name = decoder.currentString }];
 
 Q: How do I parse different XML files with the same object?
 A: Prepare different decoding methods: e.g. decodePeopleWithDecoder: and decodeNewsfeedsWithDecoder:
 
 Q: When does decodeWithDecoder: is invoked?
 A: It is invoked on the beginning of the element.
 
 Q: How to notify the root object about the end of the root element?
 A: Instead of decodeWithObject:startSelector: method use a full version: decodeWithObject:startSelector:endSelector:
 
 Q: This block-based xpath-like stream-friendly API was never done before?
 A: Pretty cool, huh :-)
 
*/


@interface OAXMLDecoder : NSObject<NSXMLParserDelegate>

@property(nonatomic, retain) NSData* xmlData;
@property(nonatomic, retain) NSXMLParser* xmlParser;
@property(nonatomic, retain) NSDictionary* currentAttributes;
@property(nonatomic, copy)   NSString* currentQualifiedName;
@property(nonatomic, copy)   NSString* currentNamespaceURI;
@property(nonatomic, copy)   NSString* currentElementName;
@property(nonatomic, copy)   NSError* error;

@property(nonatomic, readonly) NSString* currentString;
@property(nonatomic, readonly) NSString* currentStringStripped;

@property(nonatomic, assign) BOOL caseInsensitive;
@property(nonatomic, assign) BOOL succeed;
@property(nonatomic, assign) BOOL traceParsing;

- (void) decodeWithObject:(id<NSObject>)rootObject startSelector:(SEL)selector;
- (void) decodeWithObject:(id<NSObject>)rootObject startSelector:(SEL)startSelector endSelector:(SEL)endSelector;
- (void) decodeWithObject:(id<NSObject>)rootObject startSelector:(SEL)startSelector endBlock:(void(^)())endBlock;

- (void) parseElement:(NSString*)elementName startBlock:(void(^)())startBlock endBlock:(void(^)())endBlock;
- (void) parseElements:(id<NSFastEnumeration>)elements startBlock:(void(^)())startBlock endBlock:(void(^)())endBlock;
- (void) startElement:(NSString*)elementName withBlock:(void(^)())block;
- (void) startOptionalElement:(NSString*)elementName withBlock:(void(^)())block;
- (void) startElements:(id<NSFastEnumeration>)elements withBlock:(void(^)())block;
- (void) startOptionalElements:(id<NSFastEnumeration>)elements withBlock:(void(^)())block;
- (void) endElement:(NSString*)elementName withBlock:(void(^)())block;
- (void) endElements:(id<NSFastEnumeration>)elements withBlock:(void(^)())block;

- (NSString*) attributeForName:(NSString*)attrName;

@end
