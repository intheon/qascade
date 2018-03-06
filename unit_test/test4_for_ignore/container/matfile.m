function [dipoleDirectionCube fractionalAnisotropyCube dipoleHitCubeSmoothed dipoleHitCube] = calculate_mean_direction_from_harvest_dipoles(dipoleLocation, dipoleDirection, correctionFactorCube)
headGrid = pr.headGrid(2);

voxelX = unique(headGrid.xCube); % hve to swicth x and y becuase of meshgrid output which swaps
voxelY = unique(headGrid.yCube);
voxelZ = unique(headGrid.zCube);

dipoleHitCube = zeros(length(voxelX),length(voxelY),length(voxelZ));
dipoleDirectionTensorHitCube = zeros([length(voxelX),length(voxelY),length(voxelZ) 9]); % sum of direction tensors

normalizedDipoleDirection = bsxfun(@times, dipoleDirection, 1./ (sum(dipoleDirection.^2,2).^0.5));

    for dipoleNumber = 1:size(dipoleLocation,1)
        
        if mod(dipoleNumber,1500) == 0
            fprintf(['Percent done = ' num2str(round(100 * dipoleNumber / size(dipoleLocation,1))) '.\n']);
        end;
        
        [dummy dipoleXIndex] = min(abs(dipoleLocation(dipoleNumber,1) - voxelX));
        [dummy dipoleYIndex] = min(abs(dipoleLocation(dipoleNumber,2) - voxelY));
        [dummy dipoleZIndex] = min(abs(dipoleLocation(dipoleNumber,3) - voxelZ));
        
         dipoleHitCube(dipoleXIndex, dipoleYIndex, dipoleZIndex) = dipoleHitCube(dipoleXIndex, dipoleYIndex, dipoleZIndex) + 1;
	
	tensor = normalizedDipoleDirection(dipoleNumber,:)' * normalizedDipoleDirection(dipoleNumber,:);
	dipoleDirectionTensorHitCube(dipoleXIndex, dipoleYIndex, dipoleZIndex,:) = squeeze(dipoleDirectionTensorHitCube(dipoleXIndex, dipoleYIndex, dipoleZIndex,:)) + tensor(:);
       
    end;    


dipoleHitCube = permute(dipoleHitCube, [2 1 3]);
dipoleDirectionTensorHitCube = permute(dipoleDirectionTensorHitCube, [2 1 3 4]);

% multiply by the correction factor so the amount of mass inside brain becomes one for all dipoles
dipoleHitCube = dipoleHitCube .* correctionFactorCube;
for i=1:size(dipoleDirectionTensorHitCube,4)
	dipoleDirectionTensorHitCube(:,:,:,i) = dipoleDirectionTensorHitCube(:,:,:,i) .* correctionFactorCube;
end;
%%

dipoleHitCubeSmoothed = dipoleHitCube;
dipoleDirectionTensorHitCubeSmoothed = dipoleDirectionTensorHitCube;
numberOfSmoothingIterations = 15;

% the net effect is using a 0.65*2 * 15 = 19.5 mm gausian kernel
for i=1:numberOfSmoothingIterations
    dipoleHitCubeSmoothed = smooth3(dipoleHitCubeSmoothed, 'gaussian', [3 3 3]);
    for j=1:9
		dipoleDirectionTensorHitCubeSmoothed(:,:,:,j) = smooth3(dipoleDirectionTensorHitCubeSmoothed(:,:,:,j), 'gaussian', [3 3 3]);
	end;
end;



for i=1:9
dipoleDirectionTensorHitCubeSmoothed(:,:,:,i) = dipoleDirectionTensorHitCubeSmoothed(:,:,:,i) ./ dipoleHitCubeSmoothed;
end

dipoleHitCubeSmoothed(~headGrid.insideBrainCube) = 0;

dipoleDirectionTensorHitCubeSmoothed(isnan(dipoleDirectionTensorHitCubeSmoothed)) = 0;
dipoleDirectionTensorHitCubeSmoothed(isinf(dipoleDirectionTensorHitCubeSmoothed)) = 0;

%% convert the tensor to vector
dipoleDirectionCube = zeros([size(dipoleHitCubeSmoothed) 3]); % cube contains vector elements of 3 indices
fractionalAnisotropyCube = zeros(size(dipoleHitCubeSmoothed));
for i=1:size(dipoleDirectionTensorHitCubeSmoothed, 1)
	
	if mod(i,10)
		disp(round(100*i/size(dipoleDirectionTensorHitCubeSmoothed, 1)))
	end;
	
	for j=1:size(dipoleDirectionTensorHitCubeSmoothed, 2)
		for k=1:size(dipoleDirectionTensorHitCubeSmoothed, 3)
			if any(dipoleHitCubeSmoothed(i,j,k))
				tensor = vec(dipoleDirectionTensorHitCubeSmoothed(i,j,k,:));				
				[V D] = eig(reshape(tensor, [3 3]));
				dipoleDirectionCube(i,j,k,:) = V(:,3);
				dipoleDirectionCube(i,j,k,:) = V(:,3);
				
				% calculate Fractional anisotropy
				landa = diag(D);
				meanLanda = mean(landa);
				fractionalAnisotropyCube(i,j,k)  = sqrt(3/2) * sqrt( ((meanLanda - landa(1))^2 +  (meanLanda - landa(2))^2 + (meanLanda - landa(3))^2)  / sum(landa.^2));
			end;
		end;
	end;
end;
