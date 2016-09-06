
#import "PMDepthProgram.h"

@implementation PMDepthProgram

-(void)loadUniforms
{
    [super loadUniforms];
    self.planetBaseColor = [[PMVector4Uniform alloc]initWithName:"planetBaseColor" andProgram:self->_program];
    self.haloBaseColor = [[PMVector4Uniform alloc]initWithName:"haloBaseColor" andProgram:self->_program];
    [self.uniforms addObject:self.planetBaseColor];
    [self.uniforms addObject:self.haloBaseColor];
}

@end
