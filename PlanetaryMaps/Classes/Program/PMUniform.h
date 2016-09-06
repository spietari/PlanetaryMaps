
#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>

@interface PMUniform : NSObject

-(id)initWithName:(const char*)name andProgram:(GLint)program;

@property (nonatomic, assign) GLint program;
@property (nonatomic, assign) GLint location;

@property (nonatomic, assign) BOOL changed;

-(void)bind;

@end

@interface PMFloatUniform : PMUniform

@property (nonatomic, assign) GLfloat value;

@end

@interface PMFloatArrayUniform : PMUniform

@property (nonatomic, strong) NSArray *values;

@end

@interface PMIntUniform : PMUniform

@property (nonatomic, assign) GLint value;

@end

@interface PMIntArrayUniform : PMUniform

@property (nonatomic, strong) NSArray *values;

@end

@interface PMMatrixUniform : PMUniform

@property (nonatomic, assign) GLKMatrix4 value;

@end

@interface PMVector4Uniform : PMUniform

@property (nonatomic, assign) GLKVector4 value;

@end

@interface PMVector2ArrayUniform : PMFloatArrayUniform

@end

@interface PMVector3ArrayUniform : PMFloatArrayUniform

@end

@interface PMVector4ArrayUniform : PMFloatArrayUniform

@end
