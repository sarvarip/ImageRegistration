function T = MakeForwardTransform(EstimatedParameters)
% Homebrew function to create 2D transfform matrix

theta = EstimatedParameters.Rotation;
d = EstimatedParameters.Translation;

T = [cos(theta) sin(theta) d(1);
    -sin(theta) cos(theta) d(2);
         0           0      1];
