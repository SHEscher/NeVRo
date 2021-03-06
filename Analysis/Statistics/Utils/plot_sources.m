
%% Plot cortical sources for NeVRo study
% Project the spatial patterns from SSD, CSP, and SPoC into source space 
% by using eLORETA.
%
% Launch this script from top level of the NeVRo repository.
% BEFORE RUNNING: 
% - Download the "New York Head" Leadfield from https://www.parralab.org/nyhead/
% - make sure the file is called "sa_nyhead.mat"
% - Place it in "./Analysis/SourceReconstruction/eLORETA_MJ/"
% - Please note that since that file is very large (>600MB) it is on the
% .gitignore list and will not be committed/downloaded if you use this 
% within our repository or a forked version. 

% CREDITS:
% The centerpiece of this script are the calls to `m_eLORETA_nvr.m` which
% is a slightly adapted version of and a wrapper to code written by 
% MINA JAMSHIDI IDAJI
% GUIDO NOLTE
% STEFAN HAUFE
% 
% For the original work, please refer to:
% http://bbci.de/supplementary/EEGconnectivity/BBCB.html
% https://github.com/minajamshidi 
% and: 
% METH toolbox 
% https://www.uke.de/english/departments-institutes/institutes/neurophysiology-and-pathophysiology/research/research-groups/index.html 
% (as of 06/11/2019)
%
% If you make use of code in `SourceReconstruction`, please cite the 
% following paper:
% Haufe, S., & Ewald, A. (2016):
% A simulation framework for benchmarking EEG-based brain connectivity 
% estimation methodologies. 
% Brain topography, 1-18
% 
% 
% 2020 -- Felix Klotzsche -- 

%%
% set path to source plotting tools provided by MJ Idaji: 

path_MJ_tb = fullfile('.', 'Analysis', 'SourceReconstruction');
addpath(genpath(path_MJ_tb))
addpath(genpath(fullfile('.', 'Analysis', 'Statistics', 'Utils')));


dirPatterns = './Results/Patterns/';
dirOut = './Results/Plots/Patterns/Sources';
if ~exist(dirOut, 'dir')
    mkdir(dirOut)
    disp(['Created folder: ', dirOut])
end


% loading the model is slow, so I just do it once.

found_headmodel = exist(fullfile(path_MJ_tb, 'eLORETA_MJ','sa_nyhead.mat'), ...
                        'file') == 2;
assert(found_headmodel, ... 
       ['Looks like you have not loaded the New York Head model with the ', ...
       'name "sa_nyhead.mat" in the correct place. Check the header of ', ...
       '"plot_sources.m" for instructions.']);
mymodelfile= 'sa_nyhead';
load(mymodelfile);

conds = {'mov', 'nomov'}; %{'mov'}; % 

% Specify a single subject or empty vec for all subjects:
sub_id = 'NVR_S25'; %'NVR_S35'; %'NVR_S08'; %[];

patterns = {'SSD_1', 'SSD_2', 'SSD_3', 'SSD_4', ...
           'SPOC', 'CSP_max', 'CSP_min'};
       
save_plot = true;
save_format = 'epsc';
show_plot = false;
save_mats = ~true;
load_mats = true;

for cond = conds
    files_list = dir(fullfile(dirPatterns, cond{1}, [sub_id '*.csv']));
    Pattern_mats = struct();
    for i=1:size(files_list, 1)  
        subject_file = files_list(i).name;
        subject_name = strsplit(subject_file, '.');
        subject_name = subject_name{1};
        
        fprintf('---- Running subject  %s  -- condition:  %s  ----\n', ...
            subject_name, cond{1});
       
        patt_tab = readtable(fullfile(dirPatterns, cond{1}, subject_file));
        
        % give reasonable name to chanloc columns: 
        idx_rows = ismember(patt_tab.Properties.VariableNames, 'Row');
        patt_tab.Properties.VariableNames{idx_rows} = 'chanlocs';
        
        % Note that channels TP9 and TP10 were not recorded in the NY head
        % model.
        replace_tpchans = false;
        tpchans = {'TP9', 'TP10'};
        replacements = {'TP7', 'TP8'};
        % drop channels not in the NY standard head model:
        if replace_tpchans
            for tpchan_idx = 1:length(tpchans)
                tpchan = tpchans(tpchan_idx);
                idx = ismember(patt_tab.chanlocs, tpchan);
                patt_tab.chanlocs{idx} = replacements{tpchan_idx};
                bads = {'HEOG', 'VEOG'};
                idx_bads = ismember(patt_tab.chanlocs, bads);
            end
        else
            bads = {'HEOG', 'VEOG', 'TP9', 'TP10'};
            idx_bads = ismember(patt_tab.chanlocs, bads);
        end
        
        patt_tab = patt_tab(~idx_bads, :);
        
        P_mats = struct();
        for j = 1:length(patterns)
            fprintf('Plotting: %s\n', patterns{j});
            %P_mat = zeros(2004, length(patterns));
            patt_idx = ismember(patt_tab.Properties.VariableNames, ...
                patterns(j));
            P_mat = m_eLORETA_nvr(sa, table2array(patt_tab(:,patt_idx)), ...
                patt_tab.chanlocs, patterns{j}, subject_name, cond{1}, ...
                save_plot, save_format, dirOut, show_plot, 'viridis');
            if (~show_plot)
                close all;
            end
            P_mats(j).pattern = patterns{j};
            P_mats(j).weights = P_mat;
        end
        Pattern_mats(i).subject = subject_name;
        Pattern_mats(i).pattern_weights = P_mats;
    end
    
    switch cond{1}
        case 'mov'
            P_mov = Pattern_mats;
            if (save_mats)
                dirResults = fullfile(dirPatterns, 'Sources', 'mov');
                if ~exist(dirResults, 'dir') 
                    mkdir(dirResults);
                    fprintf('Created dir: %s.\n', dirResults);
                end
                filename = fullfile(dirResults, 'source_patterns_mov.mat');
                save(filename, 'P_mov');
            end
        case 'nomov'
            P_nomov = Pattern_mats;
            if (save_mats)
                dirResults = fullfile(dirPatterns, 'Sources', 'nomov');
                if ~exist(dirResults, 'dir') 
                    mkdir(dirResults);
                    fprintf('Created dir: %s.\n', dirResults);
                end
                filename = fullfile(dirResults, 'source_patterns_nomov.mat');
                save(filename, 'P_nomov');
            end
    end             
end

%% Plot averages:

% get color maps:
load cm17;
cm_vir = viridis();

patterns = {'SSD_1', 'SSD_2', 'SSD_3', 'SSD_4', ...
            'SPOC', 'CSP_max', 'CSP_min'};

%patterns = {'SSD_1', 'SSD_3'}; %{'SPOC', 'CSP_max', 'CSP_min'};

conds = {'mov', 'nomov'}; %{'mov'}; %

for cond=conds
    switch cond{1}
        case 'mov'
            if load_mats 
                fprintf('Loading data from disk.\n');
                if exist('P_mov', 'var')
                    fprintf('Overwriting data in memory w/ data from disk.\n');
                end
                dirResults = fullfile(dirPatterns, 'Sources', 'mov');
                filename = fullfile(dirResults, 'source_patterns_mov.mat');
                load(filename);
            end
            Pattern_mats = P_mov;
                
        case 'nomov'
            if load_mats 
                fprintf('Loading data from disk.\n');
                if exist('P_nomov', 'var')
                    fprintf('Overwriting data in memory w/ data from disk.\n');
                end
                dirResults = fullfile(dirPatterns, 'Sources', 'nomov');
                filename = fullfile(dirResults, 'source_patterns_nomov.mat');
                load(filename);
            end
            Pattern_mats = P_nomov;
    end
            
    for p=1:length(patterns)
        p_idx = ismember({Pattern_mats(1).pattern_weights.pattern}, ...
            patterns{p});
        all_sub_pats = zeros(2004, size(Pattern_mats, 2));
        for sub=1:size(Pattern_mats, 2)
            m = Pattern_mats(sub).pattern_weights(p_idx).weights;
            all_sub_pats(:, sub) = m / norm(m);
        end

        mean_abs_patt = mean(abs(all_sub_pats), 2); 
        P = mean_abs_patt;
        colormap = cm_vir;
        scale_unit = 'a.u.';
        smooth = 1;
        views = 1:8;
        save_plot = true;
        savepath = fullfile(dirOut, cond{1}, patterns{p}, 'mean');
        if (save_plot)
            if ~exist(savepath, 'dir'); mkdir(savepath); end
        end
        savename = fullfile(savepath, 'source');
        allplots_cortex_mina(sa, P(sa.cortex2K.in_to_cortex75K_geod), ... 
                    [min(P) max(P)], colormap, scale_unit, smooth, 'views', views, ...
                    'save', save_plot, 'savename', savename, ...
                    'saveformat', save_format);
        if (~show_plot)
            close all;
        end
    end
end
