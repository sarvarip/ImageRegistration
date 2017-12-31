% Written by Peter Sarvari
% Based on code of Dr Anil Anthony Bharath, Lecturer, Bioengineering Department
% Assumes two files (see names below) exist in current directory, which
% are single byte, unsigned data, 128x128 in size.
% Very unoptimised, but a starting point on which to build in a controlled way
% Requires:     
%               TransformImageBackwards
%               objective
%               make_forward_transform

originalfilename = ['originalimage.dat'];
rotatedfilename = ['rotatedimage.dat'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in first image
fid = fopen(originalfilename,'r');
[original,npels]=fread(fid,[128,128],'uchar');
fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in second image
fid = fopen(rotatedfilename,'r');
[rotated,npels]=fread(fid,[128,128],'uchar');
fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GAUSSIAN BLUR
% VA = conv2(original,fspecial('gaussian',[5,5],1),'same');
% VB = conv2(rotated,fspecial('gaussian',[5,5],1),'same');

VA = original;
VB = rotated;

% Create a mask to estimate the clipping of the first image region
% after transformation.
UseMaskA = ones(size(VA));  % NOT USED IN THIS VERSION 
UseMaskB = ones(size(VB));  % NOT USED IN THIS VERSION 


% Compute offset to modify coord system for rotations....
% offsetB = [mbarB nbarB] - MomentDisplacementVector' - 0.5*(1+size(VB));
offsetB = [0,0]; % If you want to rotate about somewhere other than the centre

% Set up Parameter Structure
% Paramater contains the information about the translation to 
% get from Image A to Image B.
% Start with values of zero..... Could be much faster if other values are used.
Parameters.Rotation = -0.5; Parameters.Translation = [10 10];
Parameters.CentreOffset = offsetB


% Next, begin iterative procedure to match images
% "Unpack" the data from the Parameters structure: fminsearch needs it like this
x0(1:2) = Parameters.Translation; x0(3) = Parameters.Rotation; 

options = [];
ul = [3.15, 64, 64];
ll = [-3.15, -64, -64];
f = @(x)objective(x, VA,VB,Parameters);
X = simulannealbnd(f,x0,ll,ul, options); %also works with this: X = fminsearch(f,x0,options);
% lot faster with fminsearch, but we need scale space and still less accurate
% final result
Parameters.Translation = X(1:2); Parameters.Rotation = X(3);
C = TransformImageBackwards(VB,Parameters);
D = VA - C;

% Display images and results

subplot(2,2,1);imagesc(VA);colormap(gray(200));title([originalfilename,' (A)']);
subplot(2,2,2);imagesc(VB);title([rotatedfilename,' (B)']);
subplot(2,2,3);imagesc(C);title('C (= Registered B)');
subplot(2,2,4);imagesc(D);title('Difference image (A-C)');