
#import "PMPlanetProgram.h"

@implementation PMPlanetProgram

-(void)loadUniforms
{
    [super loadUniforms];
    
    self.rotation = [[PMMatrixUniform alloc]initWithName:"rot" andProgram:self->_program];
    
    self.lineColor = [[PMVector4Uniform alloc]initWithName:"lineColor" andProgram:self->_program];;
    self.lineSpacing = [[PMFloatUniform alloc]initWithName:"lineSpacing" andProgram:self->_program];;
    
    [self.uniforms addObject:self.rotation];
    
    [self.uniforms addObject:self.lineColor];
    [self.uniforms addObject:self.lineSpacing];
}

@end
