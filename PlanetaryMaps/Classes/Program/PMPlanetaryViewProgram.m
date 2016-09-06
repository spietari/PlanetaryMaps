
#import "PMPlanetaryViewProgram.h"

@implementation PMPlanetaryViewProgram

-(void)loadUniforms
{
    [super loadUniforms];
    
    self.modelViewMatrix = [[PMMatrixUniform alloc]initWithName:"modelViewProjectionMatrix" andProgram:self->_program];
    self.dist = [[PMFloatUniform alloc]initWithName:"dist" andProgram:self->_program];
    self.planetSizeMultiplier = [[PMFloatUniform alloc]initWithName:"planetSizeMultiplier" andProgram:self->_program];

    [self.uniforms addObject:self.modelViewMatrix];
    [self.uniforms addObject:self.dist];
    [self.uniforms addObject:self.planetSizeMultiplier];
}

@end
