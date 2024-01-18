function n = randBetweenPoints(lower, upper, epsilon, sizeD1, sizeD2)
% Draw a random number from [lower + epsilon, upper - epsilon]

% INPUT
% sizeD1 and sizeD2     size of the output along dimention 1 and 2.
%                       If not specified uses 1, 1.

if nargin == 3
    size = {1, 1};
    
elseif nargin == 4
    size = {sizeD1, 1};
    
else
    size = {sizeD1, sizeD2};
end 
    
range = upper - lower - (2*epsilon);

n = (rand(size{:})*range) + lower + epsilon;

end