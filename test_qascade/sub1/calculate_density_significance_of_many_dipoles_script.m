load /data/cta/nima/harvest/harvested_dipoles_full_unique_with_scalpmap_and_corrected_channel_locationId.mat  dipoleDirection dipoleLocation dipoleRv dipoleWasBipolar dipoleScalpmap dipoleScalpmapIsValid;
%%

isLowResidualVariance = dipoleRv < 0.15;
dipoleLocation = dipoleLocation(isLowResidualVariance,:);
dipoleDirection = dipoleDirection(isLowResidualVariance,:);
dipoleWasBipolar = dipoleWasBipolar(isLowResidualVariance,:);
dipoleScalpmap = dipoleScalpmap(isLowResidualVariance,:);
dipoleScalpmapIsValid = dipoleScalpmapIsValid(isLowResidualVariance,:);
dipoleRv = dipoleRv(isLowResidualVariance);
%% find out which dipoles are in the brain volume
tic;
brainVolume =  load('standard_BEM_vol.mat'); % use MNI standard volume for dipole depth
depth = sourcedepth(dipoleLocation , brainVolume.vol)';
insideBrain = depth < -1; % less than 1 mm
percentInsideBrain = 100 * sum(insideBrain) / length(insideBrain);
toc;
%%
dipoleLocation = dipoleLocation(insideBrain,:);
dipoleDirection = dipoleDirection(insideBrain,:);
dipoleWasBipolar = dipoleWasBipolar(insideBrain,:);
dipoleScalpmap = dipoleScalpmap(insideBrain,:);
dipoleScalpmapIsValid = dipoleScalpmapIsValid(insideBrain,:);
dipoleRv = dipoleRv(insideBrain);

dipoleLocation = dipoleLocation(dipoleScalpmapIsValid,:);
dipoleDirection = dipoleDirection(dipoleScalpmapIsValid,:);
dipoleWasBipolar = dipoleWasBipolar(dipoleScalpmapIsValid,:);
dipoleScalpmap = dipoleScalpmap(dipoleScalpmapIsValid,:);
dipoleScalpmapIsValid = dipoleScalpmapIsValid(dipoleScalpmapIsValid,:);
dipoleRv = dipoleRv(dipoleScalpmapIsValid);
%% remove eye ICs
eyeDetector = pr.eyeCatch;
[isEye similarity] = eyeDetector.detectFromInterpolatedChannelWeight(dipoleScalpmap);

dipoleLocation = dipoleLocation(~isEye,:);
dipoleDirection = dipoleDirection(~isEye,:);
dipoleWasBipolar = dipoleWasBipolar(~isEye,:);
dipoleScalpmap = dipoleScalpmap(~isEye,:);
dipoleScalpmapIsValid = dipoleScalpmapIsValid(~isEye,:);
dipoleRv = dipoleRv(~isEye);

% save /data/cta/nima/harvest/harvested_inbrain_noeye_low_rv_dipoles_location_and_direction_and_rv.mat dipoleLocation dipoleDirection dipoleWasBipolar dipoleRv;
%%
headGrid = pr.headGrid(2);


voxelX = unique(headGrid.xCube); % hve to swicth x and y becuase of meshgrid output which swaps
voxelY = unique(headGrid.yCube);
voxelZ = unique(headGrid.zCube);

dipoleHitCube = zeros(length(voxelX),length(voxelY),length(voxelZ));
dipoleRvHitCube = zeros(length(voxelX),length(voxelY),length(voxelZ));

for iteration = 1:2 % two iterations, inthe first we find hit location, in the second we find associated diples for each hit location
   
    %filledHitCubeId = find(vec(permute(dipoleHitCube, [2 1 3]))>0); % swap dimension before sinc ethey will be swapped again
    filledHitCubeId = find(vec(dipoleHitCube)); % swap dimension before sinc ethey will be swapped again
    
    dipoleIdsForLinearHitCube = cell(length(filledHitCubeId),1); % a cell to contains ids of dipole hitting each location in the hit cube.
    
    
    for dipoleNumber = 1:size(dipoleLocation,1)
        
        if mod(dipoleNumber,50) == 0
            fprintf(['Percent done = ' num2str(round(100 * dipoleNumber / size(dipoleLocation,1))) '.\n']);
        end;
        
        [dummy dipoleXIndex] = min(abs(dipoleLocation(dipoleNumber,1) - voxelX));
        [dummy dipoleYIndex] = min(abs(dipoleLocation(dipoleNumber,2) - voxelY));
        [dummy dipoleZIndex] = min(abs(dipoleLocation(dipoleNumber,3) - voxelZ));
        
        if iteration == 1
            dipoleHitCube(dipoleXIndex, dipoleYIndex, dipoleZIndex) = dipoleHitCube(dipoleXIndex, dipoleYIndex, dipoleZIndex) + 1;
            dipoleRvHitCube(dipoleXIndex, dipoleYIndex, dipoleZIndex) = dipoleRvHitCube(dipoleXIndex, dipoleYIndex, dipoleZIndex) + dipoleRv(dipoleNumber);
        end;
        % collect Ids that fall into the cube
        if iteration == 2
            indexInCube = sub2ind(size(dipoleHitCube), dipoleXIndex, dipoleYIndex, dipoleZIndex);
            indexInCell = find(filledHitCubeId == indexInCube);
            dipoleIdsForLinearHitCube{indexInCell} = [dipoleIdsForLinearHitCube{indexInCell} dipoleNumber];
        end;
    end;    
end;

[x y z] = ind2sub(size(dipoleHitCube), filledHitCubeId);

dipoleHitCube = permute(dipoleHitCube, [2 1 3]);
dipoleRvHitCube = permute(dipoleRvHitCube, [2 1 3]);

filledHitCubeId = ind2sub(size(dipoleHitCube), [y x z]);

% TODO seem filledHitCubeId still doe snot work after permutation

% turn dipoleRvHitCube to contain average residual variances, his would ignore diffreent denisties
% of dipoles before averaging RVs, a better way might be to do the spatial averaging first and then
% divide.
%id = dipoleHitCube > 0;
%dipoleRvHitCube(id) = dipoleRvHitCube(id) ./ dipoleHitCube(id);
%% save dipole hit cube for visualization

[p_fdr, p_masked] = fdr( significance(headGrid.insideBrainCube), 0.05);
dipoleHitCubeMasked = dipoleHitCube;
dipoleHitCubeMasked(~headGrid.insideBrainCube) = 0;
%dipoleHitCubeMasked(significance > p_fdr) = 0;

dipoleHitCubeMasked = 1.07875e6 * dipoleHitCubeMasked / max(dipoleHitCubeMasked(:));

addpath ~/tools/volume/;
writeVTK(dipoleHitCubeMasked, '/home/nima/tools/eeg/harvest/dense_1_5-_mm_grid_dipoles_200k_not_smoothed_no_eye_depth_1_mm_inside.vtk');
%%
dipoleHitCubeSmoothed = dipoleHitCube;
dipoleRvHitCubeSmoothed = dipoleRvHitCube;
numberOfSmoothingIterations = 15;

for i=1:numberOfSmoothingIterations
    dipoleHitCubeSmoothed = smooth3(dipoleHitCubeSmoothed, 'gaussian', [3 3 3]);
    dipoleRvHitCubeSmoothed = smooth3(dipoleRvHitCubeSmoothed, 'gaussian', [3 3 3]);
   % entropyForRound(i) = entropy(dipoleHitCubeSmoothed(logical(brainVolumeMaskLinearized)));
%     if mod(i,10) == 0
%         %   mri3dplot({dipoleHitCubeSmoothed}, mri, mri3dplotOptions{:});
%     end;
end;

id = dipoleHitCubeSmoothed > 0;
dipoleRvHitCubeSmoothed(id) = dipoleRvHitCubeSmoothed(id) ./ dipoleHitCubeSmoothed(id);

% correct the scaling from smoothing with zeros in between
%dipoleRvHitCubeSmoothed = sum(dipoleHitCube(dipoleHitCube > 0)) * dipoleRvHitCubeSmoothed / sum(dipoleRvHitCubeSmoothed(dipoleHitCube > 0));
% the net effect is using a 0.65*20 = 13 mm gausian kernel
%%

dipoleHitCubeSmoothed(~headGrid.insideBrainCube) = 0;
dipoleRvHitCubeSmoothed(~headGrid.insideBrainCube) = 0;
% normalize
dipoleHitCubeSmoothed = 1e9 * dipoleHitCubeSmoothed / sum(dipoleHitCubeSmoothed(:));
% saturate top 1%
% saturationLevel = quantile(dipoleHitCubeSmoothed(dipoleHitCubeSmoothed(:) ~=0), 0.99);
% dipoleHitCubeSmoothed(dipoleHitCubeSmoothed > saturationLevel) = saturationLevel;

addpath ~/tools/volume/;
writeVTK(dipoleHitCubeSmoothed, '/home/nima/tools/eeg/harvest/dipoles_200k_smoothed_15_noeye.vtk');
writeVTK(dipoleRvHitCubeSmoothed, '/home/nima/tools/eeg/harvest/dipoles_200k_rv_smoothed_15_noeye.vtk');
%% create random uniformly distributed surrogate data for significance calculation

dipoleHitCubeSmoothed = dipoleHitCubeSmoothed / sum(dipoleHitCubeSmoothed(:));
numberOfDensityHigher = zeros(size(dipoleHitCubeSmoothed));
numberOfDensityLower = zeros(size(dipoleHitCubeSmoothed));
numberOfSurrogates = 200;
insidebRainId = find(headGrid.insideBrainCube);
currentRandomStream = RandStream('mt19937ar','Seed',0);
for surrogateNumber = 1:numberOfSurrogates
    surrogateNumber
    surrogateDipoleHitCube = zeros(size(dipoleHitCube));
   
    for i=1:size(dipoleLocation,1)
        r = currentRandomStream.randi(length(insidebRainId));
        surrogateDipoleHitCube(insidebRainId(r))  = surrogateDipoleHitCube(insidebRainId(r)) + 1;
    end;
    % smooth
    surrogateDipoleHitCubeSmoothed = surrogateDipoleHitCube;
    for i=1:numberOfSmoothingIterations
        surrogateDipoleHitCubeSmoothed = smooth3(surrogateDipoleHitCubeSmoothed, 'gaussian', [3 3 3]);
    end;
    
    surrogateDipoleHitCubeSmoothed(~headGrid.insideBrainCube) = 0;
    surrogateDipoleHitCubeSmoothed = surrogateDipoleHitCubeSmoothed /sum(surrogateDipoleHitCubeSmoothed(:));      
    
    higher = surrogateDipoleHitCubeSmoothed > dipoleHitCubeSmoothed;
    numberOfDensityHigher(higher) = numberOfDensityHigher(higher) + 1;
    
    lower = surrogateDipoleHitCubeSmoothed <= dipoleHitCubeSmoothed;
    numberOfDensityLower(lower) = numberOfDensityLower(lower) + 1;
end;

significance = max(1/numberOfSurrogates, numberOfDensityHigher / numberOfSurrogates);
significance(~headGrid.insideBrainCube) = 1;
%%
dipoleHitCubeSmoothedMasked = dipoleHitCubeSmoothed .* correctionFactorCube;
[p_fdr, p_masked] = fdr( significance(headGrid.insideBrainCube), 0.05);
dipoleHitCubeSmoothedMasked(significance > p_fdr) = 0;

dipoleHitCubeSmoothedMasked = 1e9 * dipoleHitCubeSmoothedMasked / sum(dipoleHitCubeSmoothedMasked(:));

% saturate top 1%
saturationLevel = quantile(dipoleHitCubeSmoothedMasked(dipoleHitCubeSmoothedMasked(:) ~=0), 0.99);
dipoleHitCubeSmoothedMasked(dipoleHitCubeSmoothedMasked > saturationLevel) = saturationLevel;

addpath ~/tools/volume/;
writeVTK(dipoleHitCubeSmoothedMasked, '/home/nima/tools/eeg/harvest/dipoles_200k_smoothed_masked_corrected_15_200_saturated_noeye.vtk');
%%
[valueOnFineGrid mri] = convert_coarse_grid_to_mri3d(dipoleRvHitCubeSmoothed , headGrid.xCube, headGrid.yCube, headGrid.zCube);
%[valueOnFineGrid mri] = convert_coarse_grid_to_mri3d(dipoleHitCubeSmoothedMasked, headGrid.xCube, headGrid.yCube, headGrid.zCube);


mri3dplotOptions = {'mriview' , 'side','mrislices', [-50 -30 -20 -15 -10 -5 0 5 10 15 20 25 30 40 50]};
mri3dplot(valueOnFineGrid, mri, mri3dplotOptions{:});        

%% calculate denisty correction factor (when normalizing denisty to be one for dipoles inside brain)

insidebRainId = find(headGrid.insideBrainCube);
singleDipoleHitCubeZeros = zeros(headGrid.cubeSize);
correctionFactorCube = ones(headGrid.cubeSize);

extent = round(13 * 2.5); % 2.5 std.
cubeSize= 1+ 2* extent;
surroundCube = zeros(cubeSize, cubeSize, cubeSize);
surroundCube(extent+1, extent+1, extent+1) =  1;

for j=1:15
    surroundCube = smooth3(surroundCube, 'gaussian', [3 3 3]);
end;

for i=1:length(insidebRainId)
    
    singleDipoleHitCube = singleDipoleHitCubeZeros;
   % singleDipoleHitCube(insidebRainId(i)) = 1;
    
    [x y z] = ind2sub(size(singleDipoleHitCube), insidebRainId(i));
    
    cubeMinx = max(x - extent,1);
    cubeMaxx = min(x + extent, size(singleDipoleHitCube,1));
    cubeMiny = max(y - extent,1);
    cubeMaxy = min(y + extent, size(singleDipoleHitCube,2));
    cubeMinz = max(z - extent,1);
    cubeMaxz = min(z + extent, size(singleDipoleHitCube,3));
    %
    %     surroundCube = singleDipoleHitCube(cubeMinx:cubeMaxx, cubeMiny:cubeMaxy, cubeMinz:cubeMaxz);
    %
    %     for j=1:20
    %         surroundCube = smooth3(surroundCube, 'gaussian', [3 3 3]);
    %     end;
    %
    cubeXIndex = 1:length(cubeMinx:cubeMaxx);
    if x <= extent
        cubeXIndex = extent*2 - length(cubeXIndex) + cubeXIndex;
    end;
    
    cubeYIndex = 1:length(cubeMiny:cubeMaxy);
    if y <= extent
        cubeYIndex = extent*2 - length(cubeYIndex) + cubeYIndex;
    end;
    
    cubeZIndex = 1:length(cubeMinz:cubeMaxz);
    if z <= extent
        cubeZIndex = extent*2 - length(cubeZIndex) + cubeZIndex;
    end;
    
    singleDipoleHitCube(cubeMinx:cubeMaxx, cubeMiny:cubeMaxy, cubeMinz:cubeMaxz) = surroundCube(cubeXIndex, cubeYIndex, cubeZIndex);
    
    sumBefore = sum(singleDipoleHitCube(:));
    singleDipoleHitCube(~headGrid.insideBrainCube) = 0;
    sumAfter = sum(singleDipoleHitCube(:));
    
    correctionFactorCube(insidebRainId(i)) = sumBefore / sumAfter;
    if mod(i,100) == 0
        [i round(100 *i/length(insidebRainId)) sumBefore / sumAfter]
    end;
end;

%%

[valueOnFineGrid mri] = convert_coarse_grid_to_mri3d(singleDipoleHitCube, headGrid.xCube, headGrid.yCube, headGrid.zCube);

mri3dplotOptions = {'mriview' , 'side','mrislices', [-50 -30 -20 -15 -10 -5 0 5 10 15 20 25 30 40 50]};
mri3dplot(valueOnFineGrid, mri, mri3dplotOptions{:});        

%% show areas with significantly LOW dipole density
lowDipoleDenisty = zeros(size(dipoleHitCube));
lowDensitySignificance = 1 - significance;
lowDensitySignificance(~headGrid.insideBrainCube) = 1;

logLowDensitySignificance = -log(lowDensitySignificance);
[p_fdr, p_masked] = fdr(lowDensitySignificance(headGrid.insideBrainCube), 0.05);

dipoleHitCubeSmoothedCorrected = dipoleHitCubeSmoothed .* correctionFactorCube;

value2 = zeros(size(dipoleHitCube));
value2(lowDensitySignificance < p_fdr) = 1;

maxSigLowDensity = max(vec(dipoleHitCubeSmoothedCorrected(logLowDensitySignificance < 0.05)));
value = maxSigLowDensity - dipoleHitCubeSmoothedCorrected;
value(lowDensitySignificance > p_fdr) = 0;

[valueOnFineGrid mri] = convert_coarse_grid_to_mri3d(value, headGrid.xCube, headGrid.yCube, headGrid.zCube);

mri3dplotOptions = {'mriview' , 'top','mrislices', [-50 -30 -20 -15 -10 -5 0 5 10 15 20 25 30 40 50]};
mri3dplot(valueOnFineGrid, mri, mri3dplotOptions{:});    

writeVTK(value, '/home/nima/tools/eeg/harvest/dipoles_200k_significantly_less_denisty.vtk');

%% calculate denisty in each anatomical area

dipoleHitCubeSmoothedMasked = dipoleHitCubeSmoothed .* correctionFactorCube;
[p_fdr, p_masked] = fdr( significance(headGrid.insideBrainCube), 0.05);
dipoleHitCubeSmoothedMasked(significance > p_fdr) = 0;

dipoleHitCubeSmoothedMasked = dipoleHitCubeSmoothedMasked / sum(dipoleHitCubeSmoothedMasked(:));

%% for Brodmann
insideBrainGridLocationBrodmannAreaCount = headGrid.getBrodmannData;

dipoleDensityInBrodmannArea = 0;
totalDipoleDensityInBrodmannArea = 0;
for i=1:size(insideBrainGridLocationBrodmannAreaCount,2)
    totalDipoleDensityInBrodmannArea(i) = sum(dipoleHitCubeSmoothedMasked(headGrid.insideBrainCube) .* insideBrainGridLocationBrodmannAreaCount(:,i));
    dipoleDensityInBrodmannArea(i) = totalDipoleDensityInBrodmannArea(i) / sum( insideBrainGridLocationBrodmannAreaCount(:,i));
end;

dipoleDensityInBrodmannArea(isnan(dipoleDensityInBrodmannArea)) = 0;

[sortedDensity ord] = sort(dipoleDensityInBrodmannArea, 'descend');
[dummy ordTotal] = sort(totalDipoleDensityInBrodmannArea, 'descend');

sortedDensity = sortedDensity / mean(dipoleHitCubeSmoothedMasked(headGrid.insideBrainCube));


additionalLabelForBrodmannArea = cell(52,1);
additionalLabelForBrodmannArea(1:3) = {'Primary Somatosensory'};
additionalLabelForBrodmannArea(4) = {'Primary Motor'};
additionalLabelForBrodmannArea(5) = {'Somatosensory Association'};
additionalLabelForBrodmannArea(6) = {'Premotor and Supplementary Motor'};
additionalLabelForBrodmannArea(7) = {'Somatosensory Association'};
additionalLabelForBrodmannArea(8) = {'Includes Frontal eye fields and Lateral and medial supplementary motor area (SMA)'};
additionalLabelForBrodmannArea(13) = {'Inferior Insula'};
additionalLabelForBrodmannArea(17) = {'Primary visual (V1)'};
additionalLabelForBrodmannArea(18) = {'Secondary visual (V2)'};
additionalLabelForBrodmannArea(19) = {'Associative visual (V3)'};
additionalLabelForBrodmannArea(22) = {'Auditory processing'};
additionalLabelForBrodmannArea(40) = {'Spatial and Semantic Processing'};
additionalLabelForBrodmannArea(41:42) = {'Primary and Association Auditory '};
additionalLabelForBrodmannArea(43) = {'Subcentralis'};
%functional rules, so better to not list 'taste' area.
additionalLabelForBrodmannArea(44) = {'part of Broca''s area'};
additionalLabelForBrodmannArea(45) = {'pars triangularis Broca''s area'};


fprintf('\n');fprintf('\n');
for i=1:20
    fprintf('%s \t %3.2f', ['Brodmann Area ' num2str(ord(i)) ' ' additionalLabelForBrodmannArea{ord(i)}] , (sortedDensity(i)));
    fprintf('\n');
end;



%% for LONI

anatomicalInformation =  headGrid.getAnatomicalData;


dipoleDensityInBrodmannArea = 0;
totalDipoleDensityInBrodmannArea = 0;
for i=1:size(anatomicalInformation.probabilityOfEachLocationAndBrainArea,2)
    totalDipoleDensityInBrodmannArea(i) = sum(dipoleHitCubeSmoothedMasked(headGrid.insideBrainCube) .* anatomicalInformation.probabilityOfEachLocationAndBrainArea(:,i));
    dipoleDensityInBrodmannArea(i) = totalDipoleDensityInBrodmannArea(i) / sum( anatomicalInformation.probabilityOfEachLocationAndBrainArea(:,i));
end;

dipoleDensityInBrodmannArea(isnan(dipoleDensityInBrodmannArea)) = 0;

[sortedDipoleDenisty ord] = sort(dipoleDensityInBrodmannArea, 'descend');
[dummy ordTotal] = sort(totalDipoleDensityInBrodmannArea, 'descend');

sortedDipoleDenisty = sortedDipoleDenisty / mean(dipoleHitCubeSmoothedMasked(headGrid.insideBrainCube));

fprintf('\n');fprintf('\n');
for i=1:length(ord)
    fprintf('%s \t %3.2f', anatomicalInformation.brainArealabel{ord(i)} , (sortedDipoleDenisty(i)));
    fprintf('\n');
end;


%% project average abs. scalpmap correlation


%% locations with maximum density

dipoleHitCubeSmoothed = dipoleHitCubeSmoothed .* correctionFactorCube;
[dummy index] = max(dipoleHitCubeSmoothed(headGrid.insideBrainCube));

anatomicalInformation =  headGrid.getAnatomicalData;
anatomicalInformation.probabilityOfEachLocationAndBrainArea(index,:)
%[FX,FY,FZ] = gradient(dipoleHitCubeSmoothed);

%% plot dipole denisty on cortex