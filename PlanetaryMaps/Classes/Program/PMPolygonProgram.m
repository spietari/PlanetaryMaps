
#import "PMPolygonProgram.h"

@implementation PMPolygonProgram

-(void)loadUniforms
{
    [super loadUniforms];
    
    self.rotation = [[PMMatrixUniform alloc]initWithName:"rot" andProgram:self->_program];
    self.color = [[PMVector4Uniform alloc]initWithName:"color" andProgram:self->_program];
    self.scale = [[PMFloatUniform alloc]initWithName:"scale" andProgram:self->_program];
    
    [self.uniforms addObject:self.rotation];
    [self.uniforms addObject:self.color];
    [self.uniforms addObject:self.scale];
    
}

@end
