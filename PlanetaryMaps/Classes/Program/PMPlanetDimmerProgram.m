
#import "PMPlanetDimmerProgram.h"

@implementation PMPlanetDimmerProgram

-(void)loadUniforms
{
    [super loadUniforms];
    
    self.rotation = [[PMMatrixUniform alloc]initWithName:"rot" andProgram:self->_program];
    self.edgeDimIntensity = [[PMFloatUniform alloc]initWithName:"edgeDimIntensity" andProgram:self->_program];
    
    [self.uniforms addObject:self.rotation];
    [self.uniforms addObject:self.edgeDimIntensity];
}

@end
