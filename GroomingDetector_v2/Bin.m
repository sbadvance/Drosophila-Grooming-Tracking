function [y,tn]=Bin(x,fso,fsn)
r=fso/fsn;
n=floor(length(x)/r);
tn=0:1/fsn:(n-1)/fsn;
if r~=1
y(1:n)=sum(reshape(x(1:n*r),r,n));
else
y(1:n)=x;
end