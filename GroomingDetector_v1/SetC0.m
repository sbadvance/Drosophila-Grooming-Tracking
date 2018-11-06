function varargout = SetC0(varargin)
% SetC0 MATLAB code for SetC0.fig
%      SetC0, by itself, creates a new SetC0 or raises the existing
%      singleton*.
%
%      H = SetC0 returns the handle to a new SetC0 or the handle to
%      the existing singleton*.
%
%      SetC0('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SetC0.M with the given input arguments.
%
%      SetC0('Property','Value',...) creates a new SetC0 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SetC0_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SetC0_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SetC0

% Last Modified by GUIDE v2.5 13-Jun-2017 18:14:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SetC0_OpeningFcn, ...
                   'gui_OutputFcn',  @SetC0_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SetC0 is made visible.
function SetC0_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SetC0 (see VARARGIN)

% Choose default command line output for SetC0
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes SetC0 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SetC0_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global fullname;
set(handles.text6,'string','Loading video');
[filename, pathname] = uigetfile('*.*', 'Pick a video','MultiSelect','on');
fullname=strcat(pathname,filename);
set(handles.text6,'string','Video ready');

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global fullname;
global Threshold95;
global Threshold99;
global Threshold9999;

h=waitbar(0,'Reading video');
mov=VideoReader(char(fullname));
Nframe=get(mov, 'NumberOfFrames');
index1=randi(Nframe-1,10,1);
counts=zeros(1,513);
waitbar(100,h,'Video read')
for i=1:10
    waitbar((i-1)/10,h,['Processing...' num2str(i-1) '0%']);
    testframes=int16(read(mov,[index1(i) index1(i)+1]));
    fluctuation=testframes(:,:,1,2)-testframes(:,:,1,1);
    fluctuation=fluctuation(:);
    [N,edges] = histcounts(fluctuation,[-256.5:256.5]);
    counts=counts+N;
end
waitbar(100,h,'Processing... 100%');
axisrange=max(abs(find(counts~=0)-256));
axes(handles.axes4) 
%bar([-axisrange:axisrange],counts(256-axisrange:256+axisrange))
semilogy([-axisrange:axisrange],counts(256-axisrange:256+axisrange)/sum(counts),'o')
axis([-axisrange axisrange -inf inf])
xlabel('Noise level(greyscale)')
ylabel('Probability density (Log scale)')
abscounts(1)=counts(257);
abscounts(2:257)=counts(258:end)+flip(counts(1:256));
abscounts=cumsum(abscounts)/sum(abscounts);

Threshold95=0;
while abscounts(Threshold95+1)<0.95
    Threshold95=Threshold95+1;
end

Threshold99=Threshold95;
while abscounts(Threshold99+1)<0.99
    Threshold99=Threshold99+1;
end

Threshold9999=Threshold99;
while abscounts(Threshold9999+1)<0.99999
    Threshold9999=Threshold9999+1;
end


str = ['Threshold: ' num2str(Threshold95) ' - Excludes >95% noise  ' ...
       'Threshold: ' num2str(Threshold99) ' - Excludes >99% noise  ' ...
       'Threshold: ' num2str(Threshold9999) ' - Excludes >99.99% noise'];
set(handles.text3,'string',str);
close(h)


% --- Executes during object creation, after setting all properties.
function text3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Threshold95;
global Threshold99;
global Threshold9999;
sel_button=get(handles.uibuttongroup1, 'SelectedObject');
tString=get(sel_button,'tag');
switch tString
    case 'radiobutton4'
        ThresholdC0=Threshold95;
    case 'radiobutton5'
        ThresholdC0=Threshold99;
    case 'radiobutton6'
        ThresholdC0=Threshold9999;
end
TempParameters=load('Parameters.mat');
if ThresholdC0~=[]
    TempParameters.C0=ThresholdC0;
end
save Parameters.mat -struct TempParameters;

% dlmwrite('Parameters.txt',para2print)



% --- Executes during object creation, after setting all properties.
function uibuttongroup1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uibuttongroup1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(SetC0)


% --- Executes during object creation, after setting all properties.
function axes4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes4


% --- Executes during object creation, after setting all properties.
function text6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in radiobutton4.
function radiobutton4_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton4
