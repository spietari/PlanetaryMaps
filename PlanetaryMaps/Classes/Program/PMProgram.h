
#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>

#import "PMUniform.h"

@interface PMProgram : NSObject
{
    GLuint _program;
}

-(id)initWithName:(NSString*)shaderFilename;

-(void)loadUniforms;
-(void)use;

@property (nonatomic, strong) NSMutableArray *uniforms;

@end
