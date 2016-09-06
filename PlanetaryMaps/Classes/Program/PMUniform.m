
#import "PMUniform.h"

@interface PMUniform()

@end

@implementation PMUniform

-(id)initWithName:(const char*)name andProgram:(GLint)program
{
    if (self = [super init])
    {
        self.program = program;
        self.location = glGetUniformLocation(program, name);
    }
    return self;
}

-(void)bind
{
    if (!self.changed)
    {
        return;
    }
    self.changed = NO;
    [self bindValue];
}

-(void)bindValue
{

}

@end

@implementation PMFloatUniform

-(void)setValue:(GLfloat)value
{
    if (value != _value)
    {
        _value = value;
        self.changed = YES;
    }
}

-(void)bindValue
{
    glUniform1f(self.location, self.value);
}

@end

@implementation PMFloatArrayUniform

-(void)setValues:(NSArray*)values
{
    if (_values.count != values.count)
    {
        _values = values;
        self.changed = YES;
        return;
    }
    
    for (int i = 0; i < _values.count; i++)
    {
        if (_values[i] != values[i])
        {
            break;
        }
        if (i == _values.count - 1)
        {
            return;
        }
    }
    _values = values;
    self.changed = YES;
}

-(void)bindValue
{
    GLfloat *floats = malloc(self.values.count * sizeof(GLfloat));
    for (int i = 0; i < self.values.count; i++)
    {
        floats[i] = [self.values[i] floatValue];
    }
    [self bindArray:floats];
    free(floats);
}

-(void)bindArray:(GLfloat*)floats
{
    glUniform1fv(self.location, (GLsizei)_values.count, floats);
}

@end

@implementation PMIntUniform

-(void)setValue:(GLint)value
{
    if (value != _value)
    {
        _value = value;
        self.changed = YES;
    }
}

-(void)bindValue
{
    glUniform1i(self.location, self.value);
}

@end

@implementation PMIntArrayUniform

-(void)setValues:(NSArray*)values
{
    if (_values.count != values.count)
    {
        _values = values;
        self.changed = YES;
        return;
    }
    
    for (int i = 0; i < _values.count; i++)
    {
        if (_values[i] != values[i])
        {
            break;
        }
        if (i == _values.count - 1)
        {
            return;
        }
    }
    _values = values;
    self.changed = YES;
}

-(void)bindValue
{
    GLint *ints = malloc(self.values.count * sizeof(GLfloat));
    for (int i = 0; i < self.values.count; i++)
    {
        ints[i] = [self.values[i] intValue];
    }
    [self bindArray:ints];
    free(ints);
}

-(void)bindArray:(GLint*)ints
{
    glUniform1iv(self.location, (GLsizei)_values.count, ints);
}

@end

@implementation PMMatrixUniform

-(void)setValue:(GLKMatrix4)value
{
    for (int i = 0; i < 16; i++)
    {
        if (_value.m[i] != value.m[i])
        {
            break;
        }
        if (i == 15) return;
    }
    _value = value;
    self.changed = YES;
}

-(void)bindValue
{
    glUniformMatrix4fv(self.location, 1, 0, self.value.m);
}

@end

@implementation PMVector4Uniform

-(void)setValue:(GLKVector4)value
{
    _value = value;
    self.changed = YES;
}

-(void)bindValue
{
    glUniform4fv(self.location, 1, &self.value.v[0]);
}

@end

@implementation PMVector2ArrayUniform

-(void)bindArray:(GLfloat*)floats
{
    glUniform2fv(self.location, (GLsizei)self.values.count / 2, floats);
}

@end

@implementation PMVector3ArrayUniform

-(void)bindArray:(GLfloat*)floats
{
    glUniform3fv(self.location, (GLsizei)self.values.count / 3, floats);
}

@end

@implementation PMVector4ArrayUniform

-(void)bindArray:(GLfloat*)floats
{
    glUniform4fv(self.location, (GLsizei)self.values.count / 4, floats);
}

@end



