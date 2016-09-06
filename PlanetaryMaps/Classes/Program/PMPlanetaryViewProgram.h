
#import "PMProgram.h"

@interface PMPlanetaryViewProgram : PMProgram

@property (nonatomic, strong) PMMatrixUniform *modelViewMatrix;
@property (nonatomic, strong) PMFloatUniform *dist;
@property (nonatomic, strong) PMFloatUniform *planetSizeMultiplier;

@end
