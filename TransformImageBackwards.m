function A = TransformImageBackwards(Adash,Parameters)
% Function to compute inverse of transformation
% matrix T, then to apply this to Adash to recover
% image A (hopefully)

T = make_forward_transform(Parameters)
Tinv = inv(T);

% These are needed by the Matlab version of imtransform
% HalfWidth = (size(Adash,2)-1)/2;
% HalfHeight = (size(Adash,1)-1)/2;
% BoundX = [-HalfWidth,HalfWidth];
% BoundY = [-HalfHeight,HalfHeight];

%Check if we can do it without imtransform - seems to indeed rotate it but
%performs poorly as interpolation is poor
%Here assuming image size to be 128*128 for simplicity 

vec = Adash(:);
[X, Y] = meshgrid(1:128, 1:128);
row_vec = Y(:);
col_vec = X(:);
%corresponding points matrix
%point_mat = [row_vec, col_vec, vec]';
coord_mat = [row_vec-64, col_vec-64]'; %subtract mean
coord_mat_h = [coord_mat; ones(1, 128*128)];
rotated_coord_h = (Tinv*coord_mat_h)';
rotated_coord = rotated_coord_h(:, 1:2);
rotated_coord_interp = round(rotated_coord) + 64; %add mean back
rotated_coord_vals = [rotated_coord_interp, vec];
rotated_coord_pos = rotated_coord_vals(:, 1:2) >= 1; %taking care of clipping, when rotated point starts having negative coordinates - we simply discard them
rotated_coord_overflow = rotated_coord_vals(:, 1:2) <= 128; %taking care of overflow .. index should not be bigger than image size
rotated_coord_good = rotated_coord_pos + rotated_coord_overflow;
good_indeces = find(sum(rotated_coord_good, 2) == 4);
rotated_nonclipped = rotated_coord_vals(good_indeces, :);

rotated_coord_interp1 = floor(rotated_coord) + 64; %add mean back
rotated_coord_vals1 = [rotated_coord_interp1, vec];
rotated_coord_pos1 = rotated_coord_vals1(:, 1:2) >= 1; %taking care of clipping, when rotated point starts having negative coordinates - we simply discard them
rotated_coord_overflow1 = rotated_coord_vals1(:, 1:2) <= 128; %taking care of overflow .. index should not be bigger than image size
rotated_coord_good1 = rotated_coord_pos1 + rotated_coord_overflow1;
good_indeces1 = find(sum(rotated_coord_good1, 2) == 4);
rotated_nonclipped1 = rotated_coord_vals1(good_indeces1, :);

rotated_coord_interp2 = ceil(rotated_coord) + 64; %add mean back
rotated_coord_vals2 = [rotated_coord_interp2, vec];
rotated_coord_pos2 = rotated_coord_vals2(:, 1:2) >= 1; %taking care of clipping, when rotated point starts having negative coordinates - we simply discard them
rotated_coord_overflow2 = rotated_coord_vals2(:, 1:2) <= 128; %taking care of overflow .. index should not be bigger than image size
rotated_coord_good2 = rotated_coord_pos2 + rotated_coord_overflow2;
good_indeces2 = find(sum(rotated_coord_good2, 2) == 4);
rotated_nonclipped2 = rotated_coord_vals2(good_indeces2, :);

rotated_image = zeros(128,128); %use zeros(128, 128) if filling of holes is not used; I use 100 to make these points distinctive to be able to further process them

%By doing slightly different interpolation multiple times we can get rid of
%some black holes in the image..does help a bit. Can achieve perfect
%registration with this, but not without this. 

for i = 1:size(rotated_nonclipped1, 1)
        row = rotated_nonclipped1(i, 1);
        col = rotated_nonclipped1(i, 2);
        if row>128 || col>128 || row<1 || col < 1
            disp('Error');
        end
        val = rotated_nonclipped1(i, 3);
        rotated_image(row, col) = val;
end

for i = 1:size(rotated_nonclipped2, 1)
        row = rotated_nonclipped2(i, 1);
        col = rotated_nonclipped2(i, 2);
        if row>128 || col>128 || row<1 || col < 1
            disp('Error');
        end
        val = rotated_nonclipped2(i, 3);
        rotated_image(row, col) = val;
end

for i = 1:size(rotated_nonclipped, 1)
        row = rotated_nonclipped(i, 1);
        col = rotated_nonclipped(i, 2);
        if row>128 || col>128 || row<1 || col < 1
            disp('Error');
        end
        val = rotated_nonclipped(i, 3);
        rotated_image(row, col) = val;
end

% %try to fill the black holes (where no interpolation occured) with local
% %average values...doesnt work because we cannot tell which black holes
% were originally in the image and which were created by wrong
% interpolation

% fill_bin = rotated_image == 100; %if rotated_image = 100*ones(128,128); but then background is white...
% fill_bin = single(fill_bin);
% mask = [1 1 1; 1 100 1; 1 1 1]; %mask, we will look for values where after convolution we get exactly 100; this means that there is a zero surrounded by positive values e.g. a hole in the rotated image
% [holes_r, holes_c] = find(conv2(fill_bin, mask, 'same') == 10000);
% for row = 1:length(holes_r) 
%     for col = 1:length(holes_c)
%         r = holes_r(row);
%         c = holes_c(col);
%         if c == 1 && r == 1
%             rotated_image(r, c) = 1/3*(rotated_image(r, c+1)+rotated_image(r+1,c)+rotated_image(r+1,c+1));
%         elseif c == 1 && r == 128
%             rotated_image(r, c) = 1/3*(rotated_image(r-1, c)+rotated_image(r-1, c+1)+rotated_image(r, c+1));
%         elseif r== 1 && c == 128
%             rotated_image(r, c) = 1/3*(rotated_image(r, c-1)+rotated_image(r+1, c-1)+rotated_image(r+1,c));
%         elseif r == 128 && c == 128
%             rotated_image(r, c) = 1/3*(rotated_image(r-1,c-1)+rotated_image(r-1, c)+rotated_image(r, c-1));
%         elseif c == 1
%             rotated_image(r, c) = 1/5*(rotated_image(r-1, c)+rotated_image(r-1, c+1)+rotated_image(r, c+1)+rotated_image(r+1,c)+rotated_image(r+1,c+1));
%         elseif r == 1
%             rotated_image(r, c) = 1/5*(rotated_image(r, c-1)+rotated_image(r, c+1)+rotated_image(r+1, c-1)+rotated_image(r+1,c)+rotated_image(r+1,c+1)); 
%         else
%             rotated_image(r, c) = 1/8*(rotated_image(r-1,c-1)+rotated_image(r-1, c)+rotated_image(r-1, c+1)+rotated_image(r, c-1)+rotated_image(r, c+1)+rotated_image(r+1, c-1)+rotated_image(r+1,c)+rotated_image(r+1,c+1));
%         end    
%     end
% end

A = rotated_image;

% t = maketform('affine',[Tinv(1:2,1:2); Tinv(1,3) Tinv(2,3)]);
% A = imtransform(Adash,t,'bicubic',...
%     'UData',BoundX+Parameters.CentreOffset(1),'VData',BoundY+Parameters.CentreOffset(2),...
%     'XData',BoundX,'YData',BoundY);