function sqerr = objective(x,ImageA,ImageB,Parameters)

% Put values from vector back into Parameter for convenience
Parameters.Rotation = x(3); Parameters.Translation = x(1:2);

% Try this out....
registered = TransformImageBackwards(ImageB,Parameters);

% Compute the difference
sqerr = sum(sum((registered - ImageA).^2));