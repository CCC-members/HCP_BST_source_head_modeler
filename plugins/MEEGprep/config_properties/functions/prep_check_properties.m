function [status,reject_subjects] = prep_check_properties(properties)
%CHECK_PROPERTIES Summary of this function goes here
%   Detailed explanation goes here
status = true;
reject_subjects = {};
disp("-->> Checking properties");

%%
%% Checking general params
%%
disp('-->> Checking general params');
general_params = properties.general_params.params;
if(isempty(general_params.modality) && ~isequal(general_params.modality,'EEG') && ~isequal(general_params.modality,'MEG'))
    status = false;
    fprintf(2,'\n-->> Error: The modality have to be EEG or MEG.\n');
    disp('-->> Process stopped!!!');
    return;
end
if(~isempty(general_params.colormap) && ~isequal(general_params.colormap,'none') && ~isfile(general_params.colormap))
    status = false;
    fprintf(2,'\n-->> Error: Do not exist the colormap file defined in selected dataset configuration file.\n');
    disp(general_params.colormap);
    disp('-->> Process stopped!!!');
    return;
end
if(~isfolder(general_params.bcv_config.base_path))
    status = false;
    fprintf(2,'\n-->> Error: The output path is not a folder.\n');
    disp(general_params.bcv_config.base_path);
    disp('-->> Process stopped!!!');
    return;
end
if(~isfolder(general_params.reports.output_path))
    status = false;
    fprintf(2,'\n-->> Error: The reports path is not a folder.\n');
    disp(general_params.reports.output_path);
    disp('-->> Process stopped!!!');
    return;
end

%%
%% Checking preprocessed data params
%%
disp('-->> Checking preprocessed data params');
prep_params = properties.prep_data_params.params;
prep_config = prep_params.data_config;
base_path = strrep(prep_config.base_path,'SubID','');
if(~isfolder(fullfile(base_path)))
    fprintf(2,'The prerpocessed_data base path is not a folder.\n');
    disp('Please type a correct prerpocessed_data folder in the process_prep_data.json configuration file.');
    status = false;
    disp('-->> Process stopped!!!');
    return;
end
if(isempty(prep_config.format))
    fprintf(2,'The preprocessed data format can not be empty.\n');
    disp('Please type a correct preprocessed data format in the process_prep_data.json configuration file.');
    status = false;
    disp('-->> Process stopped!!!');
    return;
end
if(prep_config.isfile)
    [path,name,ext] = fileparts(prep_config.file_location);
    if(~isequal(strcat('.',prep_config.format),ext) &&  ~isequal(lower(prep_config.format),'matrix') &&  ~isequal(lower(prep_config.format),'crosspec'))
        fprintf(2,'The preprocessed data format and the file location extension do not match.\n');
        disp('Please check the process_prep_data.json configuration file.');
        status = false;
        disp('-->> Process stopped!!!');
        return;
    end
    structures = dir(base_path);
    structures(ismember( {structures.name}, {'.', '..','derivatives'})) = [];  %remove . and ..
    structures([structures.isdir] == 0) = [];  %remove . and ..
    count_data = 0;
    for i=1:length(structures)
        structure = structures(i);
        data_file = dir(fullfile(base_path,structure.name,'**',strrep(prep_config.file_location,'SubID',structure.name)));
        if(isempty(data_file))
            count_data = count_data + 1;
            reject_subjects{length(reject_subjects)+1} = structure.name;
            continue;
        end
        data_file = fullfile(data_file.folder,data_file.name);
        if(~isfile(data_file))
            count_data = count_data + 1;
            reject_subjects{length(reject_subjects)+1} = structure.name;
        end
    end
    if(~isequal(count_data,0))
        if(isequal(count_data,length(structures)))
            fprintf(2,'Any folder in the Prep_data path have a specific file location.\n');
            fprintf(2,'We can not find the Prep_data file in this address:\n');
            fprintf(2,strcat(prep_config.file_location,'\n'));
            disp('Please check the Prep_data configuration.');
            status = false;
            disp('-->> Process stopped!!!');
            return;
        else
            warning('One or more of the Prep_data file are not correct.');
            warning('We can not find at least one of the Prep_data file in this address:');
            warning(strcat(prep_config.file_location));
            warning('Please check the Prep_data configuration.');
        end
    end
end

%%
%% Checking subject number in each folder
%%
data_base_path  = prep_config.base_path;
subjects        = dir(data_base_path);
subjects(ismember( {subjects.name}, {'.', '..'})) = [];  %remove . and ..
prep_names      = {subjects.name};

BCV_path        = general_params.bcv_config.base_path;
if(general_params.bcv_config.anat_template.use_template)
    template_name = general_params.bcv_config.anat_template.template_name;
    if(~isfile(fullfile(BCV_path,template_name,'subject.mat')))
        fprintf(2,'The template definition is wrong.\n');
        fprintf(2,'We can not find the correct structure as anatomy template:\n');
        fprintf(2,strcat('Base path:',BCV_path,'\n'));
        fprintf(2,strcat('Template name:',template_name,'\n'));
        disp('Please check the general params configuration.');
        status = false;
        disp('-->> Process stopped!!!');
        return;
    end
else
    BCV_subjects        = dir(fullfile(BCV_path,'**','subject.mat'));
    bcv_paths           = {BCV_subjects.folder};
    [~,bcv_names,~]     = fileparts(bcv_paths);
    index1              = ismember(prep_names,bcv_names);
    index2              = ismember(bcv_names,prep_names);
    prep_names(index1)  = [];
    bcv_names(index2)   = [];
    reject_subjects     = [reject_subjects , prep_names, bcv_names];
end

reject_subjects = unique(reject_subjects);
disp("--------------------------------------------------------------------------");
disp("-->> Subjects to reject");
warning('-->> Some subject do not have the correct structure');
warning('-->> The following subjects will be rejected for analysis');
disp(reject_subjects);
warning('Please check the folder structure.');

disp('-->> All properties checked.');


end

                                                                                                                                                            