
#import "PMMarkerProgram.h"

@implementation PMMarkerProgram

-(void)loadUniforms
{
    [super loadUniforms];
    
    self.rotation = [[PMMatrixUniform alloc]initWithName:"rot" andProgram:self->_program];
    [self.uniforms addObject:self.rotation];
}

@end
