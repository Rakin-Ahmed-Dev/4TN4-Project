% =========================================================
% Method 2: Improved CT Enhancement with Stronger Edge Effect
% DICOM -> Method 1 baseline -> Canny edges -> cleanup
% -> thicker edge mask -> stronger edge-guided sharpening
% =========================================================

clc;
clear;
close all;

%% -------------------------------------------------
% Step 1: List your 3 CT scan files
%% -------------------------------------------------
filenames = {
    '/Users/rakin/Documents/Engineering 4 - Winter 2026/CE 4TN4 - Image Processing/Project/IM-0015-0001.dcm'
    '/Users/rakin/Documents/Engineering 4 - Winter 2026/CE 4TN4 - Image Processing/Project/IM-0015-0050.dcm'
    '/Users/rakin/Documents/Engineering 4 - Winter 2026/CE 4TN4 - Image Processing/Project/IM-0024-0200.dcm'
};

%% -------------------------------------------------
% Step 2: Parameters
%% -------------------------------------------------

% Method 1 parameters
filterSize = [3 3];
lowPercent = 5;
highPercent = 95;

% Canny edge detector parameters
cannyThreshold = [0.08 0.20];
cannySigma = 1.0;

% Edge cleanup parameters
minEdgePixels = 20;
seClose = strel('disk', 1);

% Stronger enhancement parameters
sharpenRadius = 1.5;
sharpenAmount = 1.5;   % reduce from 2.0
edgeBoost = 0.9;       % reduce from 1.2

% Edge thickening / spreading
seDilate = strel('disk', 1);
maskBlurSigma = 1.5;   % reduce from 2.0

%% -------------------------------------------------
% Step 3: Process each CT scan
%% -------------------------------------------------
for k = 1:length(filenames)

    filename = filenames{k};

    if ~isfile(filename)
        warning('File not found: %s. Skipping.', filename);
        continue;
    end

    %% -----------------------------
    % Read DICOM image
    %% -----------------------------
    info = dicominfo(filename);
    img_raw = double(dicomread(info));

    %% -----------------------------
    % Convert to Hounsfield Units if possible
    %% -----------------------------
    img_hu = img_raw;
    if isfield(info, 'RescaleSlope') && isfield(info, 'RescaleIntercept')
        img_hu = img_raw * info.RescaleSlope + info.RescaleIntercept;
    end

    %% -----------------------------
    % Method 1 baseline
    %% -----------------------------
    img_norm = mat2gray(img_hu);

    img_filtered = medfilt2(img_norm, filterSize);

    lowVal = prctile(img_filtered(:), lowPercent);
    highVal = prctile(img_filtered(:), highPercent);

    if highVal == lowVal
        warning('Contrast stretching failed for %s. Skipping.', filename);
        continue;
    end

    img_method1 = (img_filtered - lowVal) / (highVal - lowVal);
    img_method1(img_method1 < 0) = 0;
    img_method1(img_method1 > 1) = 1;

    %% -----------------------------
    % Canny edge detection
    %% -----------------------------
    edgeMap = edge(img_method1, 'Canny', cannyThreshold, cannySigma);

    %% -----------------------------
    % Clean edge map
    %% -----------------------------
    edgeMap_clean = bwareaopen(edgeMap, minEdgePixels);
    edgeMap_clean = imclose(edgeMap_clean, seClose);
    edgeMap_clean = bwmorph(edgeMap_clean, 'clean');

    %% -----------------------------
    % Thicken edge regions
    %% -----------------------------
    edgeMap_thick = imdilate(edgeMap_clean, seDilate);

    %% -----------------------------
    % Create stronger sharpened image
    %% -----------------------------
    img_sharp = imsharpen(img_method1, ...
        'Radius', sharpenRadius, ...
        'Amount', sharpenAmount);

    %% -----------------------------
    % Smooth edge mask so enhancement spreads near boundaries
    %% -----------------------------
    edgeMask = imgaussfilt(double(edgeMap_thick), maskBlurSigma);
    edgeMask = mat2gray(edgeMask);

    %% -----------------------------
    % Stronger edge-guided enhancement
    %% -----------------------------
    img_method2 = img_method1 + edgeBoost * edgeMask .* (img_sharp - img_method1);

    % Clip values to [0,1]
    img_method2(img_method2 < 0) = 0;
    img_method2(img_method2 > 1) = 1;

    %% -----------------------------
    % Overlay image for visualization
    %% -----------------------------
    overlayImage = repmat(img_method1, [1 1 3]);
    overlayImage(:,:,1) = overlayImage(:,:,1) + 0.8 * edgeMap_thick;
    overlayImage(overlayImage > 1) = 1;

    %% -----------------------------
    % Display results
    %% -----------------------------
    figure('Name', ['Method 2 Result - Scan ', num2str(k)], 'NumberTitle', 'off');

    subplot(2,3,1);
    imshow(img_raw, []);
    title('Raw DICOM Image');

    subplot(2,3,2);
    imshow(img_method1, []);
    title('Method 1 Output');

    subplot(2,3,3);
    imshow(edgeMap, []);
    title('Canny Edge Map');

    subplot(2,3,4);
    imshow(edgeMap_thick, []);
    title('Thickened Edge Map');

    subplot(2,3,5);
    imshow(overlayImage);
    title('Edge Overlay');

    subplot(2,3,6);
    imshow(img_method2, []);
    title('Method 2 Enhanced');

    colormap gray;

    %% -----------------------------
    % Save outputs
    %% -----------------------------
    imwrite(img_method1, sprintf('ct_scan_%d_method1_output.png', k));
    imwrite(edgeMap_thick, sprintf('ct_scan_%d_edge_map.png', k));
    imwrite(img_method2, sprintf('ct_scan_%d_method2_enhanced.png', k));

    fprintf('Finished Method 2 for %s\n', filename);
    fprintf('Saved outputs for scan %d\n', k);

end

disp('All scans processed with stronger Method 2 enhancement.');
