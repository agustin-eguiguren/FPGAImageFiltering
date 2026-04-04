imgName = "hamed.bmp";
outName = "hamed_bw.mif";

A = imread(imgName);
fileID = fopen(outName, 'w');

for i = 1 : 480
    for j = 1 : 640 
        sum = 0;
        for k = 1 : 3
            sum = sum + A(i, j, k);
        end
        fwrite(fileID, sum/3);
    end
end

fprintf("Done!\n");
