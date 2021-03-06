function SimulateData

% PARAMETERS AND INITIALIZATION
k = 5.0;                      % rate (in "real units", s^-1)      %??? why this rate (supposedly the rate of the step is once every 0.5 seconds)
pauserecovery = 7.0;
dt = 0.04;                    % simulation dt, make small such that k*dt < 0.2      % why this dt? (you want to sample once every 0.1 seconds if it gave one step)
nTimeSteps = 10000;           % number of dt steps to simulate
r1 = rand(1,nTimeSteps);      % random number for monte carlo
timeStep = nan(1,nTimeSteps); % simulation time steps where steps occur
                              % (pre-allocate r1 and timeStep for speed)
Pos=5000;                        % Initial position   
Stepsize=1.5;                 % Size of the motor's step 
kT=4.11;                      % Boltzman constant (pN.nm)    
kappa=0.3;                    % Stiffness of the trap (nm/pN) 
SizeSlipVec = nan(1,nTimeSteps);

% SIMULATION
s = 0;                        % number of steps taken
t = 1;                        % simulation time points, matlab arrays start at 1
Noise = 0;                    % Initializing noise parameter   
ATPs=0;                       % Initializing number of ATP molecules 
pauseexit=0.000001;           % Number of Steps to be taken by the motor
NoSteps=0;
P=0;
SizeSlip=0;

while t < nTimeSteps,
    Noise = normrnd(0,sqrt(kT*kappa),1); % Generating noise random value 
    PosVec(t)=Pos + Noise;    % Especifying position and adding noise                
    TimeVec(t)=(t*dt)*100;    % Generating time vector to plot
   
    if SizeSlip~=0
     Pos=Pos+SizeSlip;
     SizeSlipVec(t)=SizeSlip;
     SizeSlip=0;
    else   
     if r1(1,t) < k*dt*(1-(k*dt)) % if the random number is small than this value (lambda*time - lambda*time^2) 
            ATPs=ATPs+1;          
            if ATPs >= 5 ;    % Stepping Only happens when 5 molecules bind ATP
                NoSteps=ceil(4*rand(1)); % One two three and four subunits can take the step at the same time
                 % Increment the position by four step sizes a total of 10 bp per time
                slip=rand(1);
                    if slip < 0.1                         
                         Pos=Pos-Stepsize*NoSteps;  
                         sz=exprnd(2);
                         SizeSlip=sz*10;
                    else 
                         Pos=Pos-4*Stepsize;
                         SizeSlip=0;
                    end;    
                 s = s + 1;        % take a step
                 timeStep(s) = t;  % mark the simulation time the step happened
                 ATPs=0;
            end
      end       
    end
    t = t + 1;                % increase simulation time
end

close all;
hfig = 1;
figure(hfig); clf;
plot(TimeVec,PosVec,'-');
fontSize = 10;
set(gca,'fontsize',fontSize);
set(gca,'linewidth',1);
set(gca,'layer','top');
box off;
set(hfig, 'PaperSize', [3 2.5]);
set(hfig, 'PaperPosition', [0.25 0.25 2.5 2]);
ylabel('Position, {\it bp}')
xlabel('Time, {\it s}');

hfig=2;
figure(hfig); clf;
hist(SizeSlipVec,50);
fontSize = 10;
set(gca,'fontsize',fontSize);
set(gca,'linewidth',1);
set(gca,'layer','top');
box off;
set(hfig, 'PaperSize', [3 2.5]);
set(hfig, 'PaperPosition', [0.25 0.25 2.5 2]);
ylabel('Position, {\it bp}')
xlabel('Time, {\it s}');
