
#import "PMPlanetaryViewProgram.h"

@interface PMPlanetProgram : PMPlanetaryViewProgram

@property (nonatomic, strong) PMMatrixUniform *rotation;

@property (nonatomic, strong) PMVector4Uniform *lineColor;
@property (nonatomic, strong) PMFloatUniform *lineSpacing;

@end
