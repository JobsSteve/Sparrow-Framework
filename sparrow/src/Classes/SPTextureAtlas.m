//
//  SPTextureAtlas.m
//  Sparrow
//
//  Created by Daniel Sperl on 27.06.09.
//  Copyright 2009 Incognitek. All rights reserved.
//

#import "SPTextureAtlas.h"
#import "SPMakros.h"
#import "SPTexture.h"
#import "SPGLTexture.h"
#import "SPSubTexture.h"
#import "SPRectangle.h"

// --- private interface ---------------------------------------------------------------------------

@interface SPTextureAtlas()

- (void)parseAtlasXml:(NSString*)path;

@end

// --- class implementation ------------------------------------------------------------------------

@implementation SPTextureAtlas

- (id)initWithContentsOfFile:(NSString*)path
{
    if (self = [super init])
    {
        [self parseAtlasXml:path];
    }  
    return self;
}

- (id)init
{
    return [self initWithContentsOfFile:nil];
}

- (void)parseAtlasXml:(NSString*)path
{
    SP_CREATE_POOL(pool);
    
    [mTextureRegions release];
    [mAtlasTexture release];
    
    mTextureRegions = [[NSMutableDictionary alloc] init];
    mAtlasTexture = nil;
    
    if (!path) return;
    
    NSString *fullPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:path];
    NSURL *xmlUrl = [NSURL fileURLWithPath:fullPath];
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlUrl];
    xmlParser.delegate = self;    
    BOOL success = [xmlParser parse];
    
    SP_RELEASE_POOL(pool);
    
    if (!success)    
        [NSException raise:SP_EXC_FILE_INVALID 
                    format:@"could not parse texture atlas %@. Error code: %d, domain: %@", 
                           path, xmlParser.parserError.code, xmlParser.parserError.domain];

    [xmlParser release];    
}

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName 
                                       namespaceURI:(NSString*)namespaceURI 
                                      qualifiedName:(NSString*)qName 
                                         attributes:(NSDictionary*)attributeDict 
{
    if ([elementName isEqualToString:@"SubTexture"])
    {
        NSString *name = [attributeDict valueForKey:@"name"];
        float x = [[attributeDict valueForKey:@"x"] floatValue];
        float y = [[attributeDict valueForKey:@"y"] floatValue];
        float width = [[attributeDict valueForKey:@"width"] floatValue];
        float height = [[attributeDict valueForKey:@"height"] floatValue];        
        
        [mTextureRegions setObject:[SPRectangle rectangleWithX:x y:y width:width height:height]
                            forKey:name];        
    }
    else if ([elementName isEqualToString:@"TextureAtlas"])
    {
        // load atlas texture
        NSString *imagePath = [attributeDict valueForKey:@"imagePath"];        
        mAtlasTexture = [[SPTexture textureWithContentsOfFile:imagePath] retain];
    }
}

- (int)count
{
    return [mTextureRegions count];
}

- (SPTexture*)textureByName:(NSString*)name
{
    SPRectangle *region = [mTextureRegions objectForKey:name];
    if (!region) return nil;    
    return [SPSubTexture textureWithRegion:region ofTexture:mAtlasTexture];    
}

+ (SPTextureAtlas*)atlasWithContentsOfFile:(NSString*)path
{
    return [[[SPTextureAtlas alloc] initWithContentsOfFile:path] autorelease];
}

- (void)dealloc
{
    [mAtlasTexture release];
    [mTextureRegions release];
    [super dealloc];
}

@end
