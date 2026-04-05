imgName = "hamed.bmp";
outName = "hamed_bw.mif";

A = imread(imgName);
J = imresize(A, [160 213]); 
imshow(J);
grayJ = rgb2gray(J); 

whos grayJ;

[rows, cols] = size(grayJ);
total_pixels = rows * cols;

fileID = fopen(outName, 'w');

fprintf(fileID, 'DEPTH = %d;\n', total_pixels);
fprintf(fileID, 'WIDTH = 8;\n');
fprintf(fileID, 'ADDRESS_RADIX = DEC;\n');
fprintf(fileID, 'DATA_RADIX = HEX;\n\n');
fprintf(fileID, 'CONTENT BEGIN\n');

addr = 0;
for i = 1:rows
    for j = 1:cols
        pixel_val = grayJ(i, j);
        fprintf(fileID, '    %d : %02X;\n', addr,  mod((i+j), 256) ); % use pixel_val instead
        addr = addr + 1;
    end
end

fprintf(fileID, 'END;\n');
fclose(fileID);
fprintf("Done!\n Image is: %d*%d Total size is: %d\n", size(J,1), size(J,2), addr);