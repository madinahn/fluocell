% function data = get_image(data,new_first_file)
% This is the file I/O interface of Fluocell
% Get image from files depending on different protols
% When enabled, the get_image function also load background, the
% cropping rectangle, or the mask. 
% Initialize the global variable fluocell_data_roi_move


% Copyright: Shaoying Lu and Yingxiao Wang 2011

function data = get_image(data,new_first_file)
% A global variable spans all the functions where this variable is declared
% global.
global fluocell_data_roi_move
if isempty(fluocell_data_roi_move),
    fluocell_data_roi_move = 0;
end;

% update the first file
% pattern = data.index_pattern{2}; 
index_str = sprintf(data.index_pattern{2}, data.index);
if new_first_file
    data.first_file = strcat(data.path, data.prefix, data.postfix);
    data.file{1} = data.first_file;
else
    num_matching = length(regexp(data.first_file, data.index_pattern{1}));
    data.file{1} = regexprep(data.first_file, data.index_pattern{1}, ...
        index_str, num_matching);
end;
if exist(data.file{1}, 'file'),
    im = imread(data.file{1});
else
    data.im{1} = [];
    return;
end;

% Load background into data.bg_bw and data.bg_poly
if fluocell_data_roi_move,
    if isfield(data, 'bg_poly'),
        temp = rmfield(data,'bg_poly'); clear data;
        data = rmfield(temp, 'bg_bw'); clear temp;
    end;
    if isfield(data, 'roi_poly'),
        temp = rmfield(data, 'roi_poly'); clear data;
        data = temp; clear temp;
    end;
    fluocell_data_roi_move = 0;
end;
if isfield(data,'subtract_background') && data.subtract_background...
        && ~isfield(data, 'bg_bw'),
    %im = imread(data.file{1});
    bg_file = 'background.mat';
    [data.bg_bw, data.bg_poly]= get_background(im, strcat(data.output_path, bg_file));
    %clear im; 
end;

% load cropping rectangle and rotate_image if needed.
if isfield(data, 'crop_image') && data.crop_image...
        && ~isfield(data,'rectangle'),
    %im = imread(data.file{1});
    if isfield(data, 'rotate_image') && data.rotate_image,
         im_rot = imrotate(im, data.angle);
         clear im; im = im_rot; clear im_rot;
    end;
    data.rectangle = get_rectangle(im, strcat(data.output_path, 'rectangle.mat'));
    temp = imcrop(im, data.rectangle); clear im;
    im = temp; clear temp;
    %clear im;
elseif isfield(data, 'crop_image') && ~data.crop_image...
        && isfield(data, 'rectangle'),
    data = rmfield(data, 'rectangle');
end


% Initialize data.time, data.value, data.ratio, data.donor, data.acceptor
% set data.num_rois, and data.roi_poly

clear im_size
roi_file = strcat(data.output_path, 'roi.mat');
if isfield(data, 'quantify_roi') && data.quantify_roi,
    if isfield(data, 'num_rois') ,
        num_rois = data.num_rois;
    else
        num_rois = 1;
    end;
    if ~isfield(data,'value'),
        data.time = Inf*ones(200, 2);
        data.value = Inf*ones(200, 3);
        data.ratio = Inf*ones(200, num_rois);
        data.channel1 = Inf*ones(200, num_rois);
        data.channel2 = Inf*ones(200, num_rois);
        data.channel1_bg = Inf*ones(200, 1);
        data.channel2_bg = Inf*ones(200, 1);
        data.cell_size = Inf*ones(200,1);
        % two column for time
        % one columns for value
    end;
    % Load the ROIs
    if ~isfield(data,'roi_poly'),
        %im = imread(data.file{1});
        [data.roi_bw, data.roi_poly] = ...
            get_polygon(im, roi_file, 'Please choose the ROI now.', ...
            'polygon_type', 'any', 'num_polygons', num_rois);
        %clear im;
    end;  
end;

% Load the mask if needed. 
if isfield(data, 'need_apply_mask') && data.need_apply_mask,
    file_name = strcat(data.output_path, 'mask.mat');
    if ~isfield(data, 'mask'),
        % Correct the title for mask selection
        temp = get_polygon(data.im{1}, file_name, 'Please Choose the Mask Region');
        data.mask = temp{1}; clear temp;
    end;
end;
clear im;


% For different protocols,
% load the names of image files into data.file
% load images from data.file to data.im
switch data.protocol;
    case 'FRET',
        data.file{2} = regexprep(data.file{1}, data.channel_pattern{1},...
            data.channel_pattern{2});
        for i = 1:2,
            data.im{i} = my_imread(data.file{i}, data);
        end;
        % ratio_image_file and file_type
       fret_file = get_fret_file(data, data.file{1});
       data.file{3} = strcat(fret_file, '.', 'tiff');
       data.file{4} = 'tiff';

    case 'FRET-Intensity', 
        data.file{2} = regexprep(data.file{1}, data.channel_pattern{1},...
            data.channel_pattern{2});
        data.file{3} = regexprep(data.file{1}, data.channel_pattern{1}, ...
            data.channel_pattern{3});
        for i = 1:3,
            data.im{i} = my_imread(data.file{i}, data);
        end;
        % ratio_image_file and file_type
        fret_file = get_fret_file(data, data.file{1});
        data.file{4} = strcat(fret_file, '.', 'tiff');
        data.file{5} = 'tiff';

    case 'FRET-DIC',
        data.file{2} = regexprep(data.file{1}, data.channel_pattern{1},...
            data.channel_pattern{2});
        data.file{3} = regexprep(data.file{1}, data.channel_pattern{1}, ...
            data.channel_pattern{3});
        for i = 1:3,
            data.im{i} = my_imread(data.file{i}, data);
        end;
        % ratio_image_file and file_type
        fret_file = get_fret_file(data, data.file{1});
        data.file{4} = strcat(fret_file, '.', 'tiff');
        data.file{5} = 'tiff';

    case 'FRET-Intensity-DIC',
        data.file{2} = regexprep(data.file{1}, data.channel_pattern{1},...
            data.channel_pattern{2});
        data.file{3} = regexprep(data.file{1}, data.channel_pattern{1}, ...
            data.channel_pattern{3}); % 3- intensity
        data.file{4} = regexprep(data.file{1}, data.channel_pattern{1}, ...
            data.channel_pattern{4}); % 4- DIC        
        for i = 1:4,
            data.im{i} = my_imread(data.file{i}, data);
        end;
        % ratio_image_file and file_type
        fret_file = get_fret_file(data, data.file{1});
        data.file{5} = strcat(fret_file, '.', 'tiff');
        data.file{6} = 'tiff';

    case {'FLIM', 'STED'}, 
        data.file{2} = regexprep(data.file{1}, data.channel_pattern{1},...
            data.channel_pattern{2});
        for i = 1:2,
            if exist(data.file{i}, 'file') ==2,
                temp = my_imread(data.file{i}, data);
            else
                temp = [];
                display(sprintf('%s : %s\n', data.file{i}, 'This file does not exist!'));
            end;
            data.im{i} = uint16(temp); clear temp;
        end;
        % ratio_image_file and file_type
       fret_file = get_fret_file(data, data.file{1});
       data.file{3} = strcat(fret_file, '.', 'tiff');
       data.file{4} = 'tiff';

    case  'Intensity',
        if exist(data.file{1}, 'file')==2,
            data.im{1} = imread(data.file{1});
            data.file{2} = strcat(data.output_path, 'processed_im', index_str, '.tiff');
        else
            display(sprintf('%s : %s\n', data.file{1}, 'This file does not exist!'));
        end; % if exist(data.file{1}, 'file')==2,            
    case 'Intensity-Processing',
        data.file{2} = strcat(data.output_path, 'processed_im', index_str, '.tiff');
        data.file{3} = 'tiff';
        data.im{1} = my_imread(data.file{1}, data);
    case 'Intensity-DIC-Processing',
        % There is someproblem with the long path string with this, so
        % replace with the statements below instead
        data.file{2} = regexprep(data.file{1}, data.channel_pattern{1},...
            data.channel_pattern{2});
%         temp = regexprep(strcat(data.prefix, '.', index_str), data.channel_pattern{1},...
%             data.channel_pattern{2});
%         data.file{2} = strcat(data.path, temp); clear temp;
        data.file{3} = strcat(data.output_path, 'processed_im', index_str, '.tiff');
        data.file{4} = 'tiff';
        for i = 1:2,
            data.im{i} = my_imread(data.file{i}, data);
        end;
end
return;

