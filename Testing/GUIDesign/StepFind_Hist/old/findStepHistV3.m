function outS = findStepHistV3(inContour, inYRes, inNoise, p)
%Follows Aggarwal's method for iterative step detection
%V2: Made ~10x quicker (but more memory-intensive) by interpolating first, out of the loop
%V3: Increasing performance for wide-Y values by skipping some large step calculations (dBP > 30)

if nargin < 3 || isempty(inNoise)
    inNoise = estimateNoise(inContour);
end
if nargin < 2
    inYRes = 0.1;
end

%a is our vector of y-values, with which we granularize our search
a = min(inContour):inYRes:max(inContour);

len = length(inContour);
hei = length(a);

if nargin < 4 || isempty(p)
    %Start with p = exp(-4.5), or W=9*noise
    p = [-100000, exp(-4.5); 100000, exp(-4.5)];
end

%Or seed with, say, a gaussian around 10bp

%Precalculate W(j,:) = penalty vector for jth iter. (zero at jth position)
W = zeros(hei);
for j = 1:hei
%Code had -2* here, but I think we need it stronger.
    W(j,:) = -9*inNoise*log( interp1(p(:,1),p(:,2),a(j)-a) );
    W(j,j) = 0;
end

%S is a j x i matrix; S(j,:) is the best path to get to a(j)
S = a';

%J stores the current score at each point.
J = (inContour(1) - a).^2;

%Some timing stuff - speed isnt constant, since there's two parts: computation (constant) and memory allocation (linear with i)
wb = waitbar(0,'Finding steps...');
startT = tic;
dt = 10;
%Find the optimal path to traverse to any ending pt. by going one point at a time
for i = 1:len-1
    %Some timing stuff
    if rem(i, dt) == 0
        pct = (i/len);
        t = toc(startT) * ((1/pct) - 1);
        if t > 60
            tm = floor(t / 60);
            ts = floor(rem(t,60));
            tmsg = [num2str(tm) 'm' num2str(ts) 's'];
        else
            ts = floor(t);
            tmsg = [num2str(ts) 's'];
        end
        waitbar(pct,wb,['Finding steps, ETA: ' tmsg])
    end
    
    %Create new containers for J, S
    Jnew = Inf(1,hei);
    Snew = zeros(hei,i+1);
    %Calculate cost of going from any point to a(j) at time i+1
    for j = 1:hei 
        %Skip any candidate point over 30bp away from the trace
        dx = abs(inContour(i+1) - a(j));
        if dx <= 30
            %Calculate new (differential) quadratic error for each trajectory
            g = (dx)^2 + W(j,:);
            %And add it to the rest, find the minimum
            Jtemp = J+g;
            [val, ind] = min(Jtemp);
            %Collect our victor: write its new score J and new path S
            Jnew(j) = val;
            Snew(j,:) = [S(ind,:) a(j)];
        end
    end
    %Save them for the next iteration
    J = Jnew;
    S = Snew;
end
delete(wb);
%Now we have J and S for the whole trace, just need to pick the victor
[~, ind] = min(J);
outS = S(ind,:);
toc(startT);
   