
#import "PMColorProgram.h"

@implementation PMColorProgram

-(void)loadUniforms
{
    [super loadUniforms];
    self.color = [[PMVector4Uniform alloc]initWithName:"color" andProgram:self->_program];
    [self.uniforms addObject:self.color];
}

@end
