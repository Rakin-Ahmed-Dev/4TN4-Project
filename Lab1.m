filename = "C:\Users\Zayeed\OneDrive - McMaster University\5th Year\ELECENG 4BF4\Labs\lab1-AM\lab1_AM\CT\pt5\Dose_Record - 2312\Dose_Report_999\IM-0003-0001.dcm";
info = dicominfo(filename);
img = double(dicomread(info));

imshow(img, []); colormap gray;


% draw ROI interactively
roi = drawcircle;     % or drawrectangle, drawpolygon etc.
roi2 = drawcircle;

mask = createMask(roi);
mask2 = createMask(roi2);

values = img(mask);
values2 = img(mask2);

meanHU = mean(values)
stdHU  = std(values)
minHU  = min(values)
maxHU  = max(values)
meanHU2 = mean(values2)
stdHU2  = std(values2)
minHU2  = min(values2)
maxHU2  = max(values2)