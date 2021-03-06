function outData = applyGaussFilter( fun, inData, inWidth, inSD )
% Filters the input dataset inData with a diffOfGauss filter with params inWidth, inSD

width = floor((inWidth-1)/2);
outData = zeros(1,length(inData)-2*width);
if nargin < 4
    fil = fun(inWidth);
else
    fil = fun(inWidth,inSD);
end

for i = 1:length(outData)
    outData(i) = inData(i:i+2*width) * fil';
end
end

