% =========================================================
% Method 1: Baseline CT Enhancement for Multiple CT Scans
% DICOM -> Normalize -> Median Filter -> Contrast Stretch
% =========================================================

clc;
clear;
close all;

%% --------------------------------
% Step 1: List your 3 CT scan files
%% --------------------------------
filenames = {
    '/Users/rakin/Documents/Engineering 4 - Winter 2026/CE 4TN4 - Image Processing/Project/IM-0015-0001.dcm'
    '/Users/rakin/Documents/Engineering 4 - Winter 2026/CE 4TN4 - Image Processing/Project/IM-0015-0050.dcm'
    '/Users/rakin/Documents/Engineering 4 - Winter 2026/CE 4TN4 - Image Processing/Project/IM-0024-0200.dcm'
};

%% --------------------------------
% Step 2: Set processing parameters
%% --------------------------------
filterSize = [3 3];   % try [5 5] if you want stronger smoothing
lowPercent = 2;
highPercent = 98;

%% --------------------------------
% Step 3: Loop through each CT scan
%% --------------------------------
for k = 1:length(filenames)

    % Get current file name
    filename = filenames{k};

    % Check if file exists
    if ~isfile(filename)
        warning('File not found: %s. Skipping this file.', filename);
        continue;
    end

    %% Read DICOM image
    info = dicominfo(filename);
    img_raw = double(dicomread(info));

    %% Convert to Hounsfield Units if fields exist
    img_hu = img_raw;
    if isfield(info, 'RescaleSlope') && isfield(info, 'RescaleIntercept')
        img_hu = img_raw * info.RescaleSlope + info.RescaleIntercept;
    end

    %% Normalize image to [0,1]
    img_norm = mat2gray(img_hu);

    %% Median filtering
    img_filtered = medfilt2(img_norm, filterSize);

    %% Percentile-based contrast stretching
    lowVal  = prctile(img_filtered(:), lowPercent);
    highVal = prctile(img_filtered(:), highPercent);

    % Prevent divide-by-zero
    if highVal == lowVal
        warning('Contrast stretching failed for file: %s. Skipping.', filename);
        continue;
    end

    img_enhanced = (img_filtered - lowVal) / (highVal - lowVal);

    % Clip values to [0,1]
    img_enhanced(img_enhanced < 0) = 0;
    img_enhanced(img_enhanced > 1) = 1;

    %% Display results for current image
    figure('Name', ['Method 1 Result - Scan ', num2str(k)], 'NumberTitle', 'off');

    subplot(2,2,1);
    imshow(img_raw, []);
    title('Raw DICOM Image');

    subplot(2,2,2);
    imshow(img_norm, []);
    title('Normalized Image');

    subplot(2,2,3);
    imshow(img_filtered, []);
    title('Median Filtered');

    subplot(2,2,4);
    imshow(img_enhanced, []);
    title('Contrast Enhanced');

    colormap gray;

    %% Save output image
    outputName = sprintf('ct_scan_%d_method1_enhanced.png', k);
    imwrite(img_enhanced, outputName);

    fprintf('Finished processing %s\n', filename);
    fprintf('Saved enhanced image as %s\n', outputName);

end

disp('All scans processed.');
