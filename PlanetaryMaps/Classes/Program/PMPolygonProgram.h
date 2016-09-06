
#import "PMPlanetaryViewProgram.h"

@interface PMPolygonProgram : PMPlanetaryViewProgram

@property (nonatomic, strong) PMMatrixUniform *rotation;
@property (nonatomic, strong) PMVector4Uniform *color;
@property (nonatomic, strong) PMFloatUniform *scale;

@end
