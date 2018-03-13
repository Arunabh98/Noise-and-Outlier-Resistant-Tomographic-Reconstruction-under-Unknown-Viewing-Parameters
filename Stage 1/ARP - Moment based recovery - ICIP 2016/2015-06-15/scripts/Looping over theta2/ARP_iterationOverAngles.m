%%
% Reconstruction from projection data from unknown angles
% In this script we'll implement angle recovery. From there, reconstruction
% is quite directly possible

clear; clc;
rng(200);

%% %%%%%%%%%%%%% PARAMETERS %%%%%%%%%%%%%
thetas = (0:179); % Projections to sample from
numkeep = 30; % Number of abgles to recompute from
sigmaNoiseFraction = 0.00;


%% %%%%%%%%%%%%% A. GENERATE INPUT DATA %%%%%%%%%%%%%%%%%

%%%% Define image I %%%%
%I = phantom(200);
I = rgb2gray(imread('../images/640px-napoleon.jpg'));

% figure();
% imshow(I,'InitialMagnification','fit');

%%%% Calculate projections %%%%

[P, svector] = radon(I, thetas); % P(s, theta)
% figure();
% imshow(P / max(max(P)), [], 'Xdata', [0 179] , 'Ydata', svector, 'InitialMagnification','fit');
% iptsetpref('ImshowAxesVisible','on')
% xlabel('Angle \theta')
% ylabel('s')
% title('Projections P_\theta(s)')

% Normalize s to a unit circle
smax = max(abs(svector));
svector = svector / smax;
keep = randperm(size(P,2), numkeep);
%keep = randi([1 size(P,2)], numkeep, 1);
%keep = sort(keep);

thetaskeep = thetas(keep);
Pgiven = P(:, keep);
expectedanswer = (thetaskeep - thetaskeep(1))';

%%%% Add noise

ref = std(Pgiven(:));
sigmaNoise = sigmaNoiseFraction * ref;
Pgiven = Pgiven + normrnd(0, sigmaNoise, size(Pgiven));
Pgiven = max(0, Pgiven);


%%%% Calculate Projection moments from projections %%%%

kmax = numkeep - 1; %Number of projection moments. This equality is because this kmax is the number needed for calculating image moments
%"The image moments of the kth order are determined by 
% a set of projection moments of the kth order from
% k+1 given views."

%TODO: Only first order moments are needed
M=ones(size(Pgiven,2), kmax+1); % each column represents kth moments for one k, for all directions
for k = 0:kmax
    for i = 1:size(Pgiven,2)
        M(i, k+1) = calculateProjectionMoment(Pgiven(:,i), svector, k);
    end
end

%The resulting M is the limited set of Projection Moments
% M(thetanumber, momentnumber)
      M(:,1); % 0th projection moment
      M(:,2); %

%% %%%%%%%%%%% (POTENTIALLY) DENOISING TO BE DONE HERE %%%%%%%%

      
%% %%%%%%%%%%%%%%% B. RECOVER ANGLES %%%%%%%%%%%%%%%%%

theta1 = 0;
bestanswer = zeros(numkeep);
besterror = Inf;

rangethetas = 1:179;
ctr = 1;
totalerrorvector = zeros(size(rangethetas));

for theta2 = rangethetas    %TODO: Increase resolution
                            %     (Possibly in multiple iterations
                            %      in negihbourhood of best estimate)
    theta2
    
    %%  Calculate (first order) image moments from 2 projection moments and angles
    
    PM = M(1:2, 2);
    A = [cosd(theta1), sind(theta1); cosd(theta2), sind(theta2)];
    
    IM = A\PM;   % = A^-1 * PM
    
    %%  Estimate all thetas from image moments and remaining projection moments
    
    estimatedthetas = zeros(numkeep,1);
    estimatedthetas(2) = theta2; 
        
    totalerror = 0; 
    for i = 3:numkeep
        PMi = [M(1,2); M(i,2)];
        [theta_i, currenterror] = bestTheta2(IM, PMi);
        estimatedthetas(i) = theta_i;
        totalerror = totalerror + currenterror;
    end
      
    totalerrorvector(ctr) = totalerror;
    ctr = ctr + 1;
    %% Evaluate error in moment estimates. Return thetas with lowest error
    if totalerror < besterror
        bestanswer = estimatedthetas;
        besterror = totalerror;
    end

    
    
%      error = sum(abs(estimatedthetas - expectedanswer));
%      if error < besterror
%          bestanswer = estimatedthetas;
%          besterror = error;
%      end
    
end

disp(strcat('Expected Answer | BestAnswer')); 
[expectedanswer, bestanswer]
%disp(strcat('Total Absolute Error: ',num2str(sum(abs(bestanswer - expectedanswer)))));

figure();
plot(rangethetas, totalerrorvector);

figure();
plot(rangethetas(floor(length(rangethetas)/4) : floor(3*length(rangethetas)/4)) , totalerrorvector(floor(length(totalerrorvector)/4) : floor(3*length(totalerrorvector)/4) ));

low  = max(1, bestanswer(2) - 30);
high = min(bestanswer(2) + 30, 179);

figure();
plot(rangethetas(low:high), totalerrorvector(low:high));
%plot(rangethetas(1:100), totalerrorvector(1:100));


%% %%%%%% COMMENTS %%%%%%%%
%1. Looping over 360 degrees becomes necessary because theta2 - theta1
%     could be as large as 180 deg
%2. There IS a closed form solution to calculating thetas in with
%     constraints. Implement this. TODO.
%3. Guessing and fixing one theta allows first order moments. Two loops
%     will allow 2nd order moments. We can trade-off between processing
%     time and accuracy. How is overall process accuracy affected by this?
% 


%% %%%%%%%%%%%%%%%%%%%%%%%%%%
%  disp('Image moments directly from image')
%  imageMomentFromImage(I, 1, 0, [100;100], smax)
%  imageMomentFromImage(I, 0, 1, [100;100], smax)










