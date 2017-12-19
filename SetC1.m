function varargout = SetC1(varargin)
% SetC1 MATLAB code for SetC1.fig
%      SetC1, by itself, creates a new SetC1 or raises the existing
%      singleton*.
%
%      H = SetC1 returns the handle to a new SetC1 or the handle to
%      the existing singleton*.
%
%      SetC1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SetC1.M with the given input arguments.
%
%      SetC1('Property','Value',...) creates a new SetC1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SetC1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SetC1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SetC1

% Last Modified by GUIDE v2.5 05-Jun-2017 17:03:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SetC1_OpeningFcn, ...
                   'gui_OutputFcn',  @SetC1_OutputFcn, ...
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


% --- Executes just before SetC1 is made visible.
function SetC1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SetC1 (see VARARGIN)

% Choose default command line output for SetC1
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SetC1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);
global ThresholdC1;
global MaxMaxArea;
ThresholdC1=[];
MaxMaxArea=[];


% --- Outputs from this function are returned to the command line.
function varargout = SetC1_OutputFcn(hObject, eventdata, handles) 
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
set(handles.text3,'string','Loading video');
[filename, pathname] = uigetfile('*.*', 'Pick a video','MultiSelect','on');
fullname=strcat(pathname,filename);
set(handles.text3,'string','Video ready');


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global fullname;
global TemplateFrame
load('Parameters.mat');
h=waitbar(0,'Creating Background');
mov=VideoReader(char(fullname));
Nframe=get(mov, 'NumberOfFrames');
if Nframe>10000
    Nframe=10000;
end
TemplateFrame=read(mov,randi(Nframe,1,1));
TemplateFrame=rgb2gray(TemplateFrame);

Ncontrast=floor(linspace(2,Nframe,7));

for i=1:7
    waitbar((i-1)/7,h,['Creating Background...' num2str(floor((i-1)/7*100)) '%'])
    ContrastFrame=read(mov,Ncontrast(i));
    ContrastFrame=rgb2gray(ContrastFrame);
    TemplateFrame(TemplateFrame<=ContrastFrame-C0)=ContrastFrame(TemplateFrame<=ContrastFrame-C0);
end
waitbar(100,h,'Creating Background...100%');
axes(handles.axes1)
imshow(TemplateFrame)
close(h)

% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global TemplateFrame;
global fullname;
global MaxMaxArea;
load('Parameters.mat');
mov=VideoReader(char(fullname));
Nframe=get(mov, 'NumberOfFrames');
if Nframe>10000
    Nframe=10000;
end


h=waitbar(0,'Processing... 0%');
for i=1:Nframe
    waitbar((i-1)/Nframe,h,['Processing...' num2str(floor((i-1)/Nframe*100)) '%'])
    BinaryFrame=uint8(zeros(size(TemplateFrame)));
    CurrentFrame=rgb2gray(read(mov,i));
    BinaryFrame(CurrentFrame<=TemplateFrame-C0)=uint8(255);
    CC = bwconncomp(BinaryFrame);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [biggest,idx] = max(numPixels);
    MaxArea(i)=biggest;
end
close(h)
MaxMaxArea=max(MaxArea)
min(MaxArea)
[N,edges]=histcounts(MaxArea,'BinMethod','integers','Normalization', 'probability');
axes(handles.axes2)
bar(edges(1:end-1),N)



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
global ThresholdC1;
ThresholdC1= str2num(get(hObject,'String'));


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ThresholdC1;
global MaxMaxArea;

if ~(ThresholdC1==[] & MaxMaxArea==[])
    TempParameters=load('Parameters.mat');
    if isempty(ThresholdC1)
        TempParameters.C1=ceil(prctile(MaxMaxArea,95));
    else   
        TempParameters.C1=ThresholdC1;
    end
    save Parameters.mat -struct TempParameters;
end

% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(SetC1)


% --- Executes during object creation, after setting all properties.
function text3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
