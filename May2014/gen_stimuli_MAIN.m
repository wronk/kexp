%   function [output] = gen_stimuli_MAIN (inter_wheel_msec)   
%   Author: Karl Marrett
%  Uses dopping instead of dropped letters, thus all dropped letter code
%  has been removed
%   generates wheeled stimulus
%   Includes a preblock primer where target letters are played in their respective location and pitch, and
%   a post_block to provide time between trials.
% Key params
% WN number of wheels
% IWI timing between letters played from one wheel to the next
% ILI timing between letters played with one wheel (i.e. 'A' 'B')
% tone/drop whether oddballs are either dropped or played in a tone
% training blocks
% single letter for each block


clearvars -except inter_wheel_msec z

PATH = '~/Dropbox/LABSN/Files_Script/';%local letter and output directory
output_path = strcat(PATH, 'stimuli_output/May');%directory where subject stimulus will be saved for each computer
letter_path = strcat(PATH, 'monotone_220Hz_24414'); %directory to untrimmed letters %linux home
K70_dir = strcat(PATH, 'K70'); % ubuntu home
tone_dir = strcat(PATH, 'stimuli_tones'); %ubuntu home
num_dir = strcat(PATH, 'number_processed');  %ubuntu home

letterArray = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z'}; %does not contain W
letterArray = {'A' 'B' 'F' 'O' 'E' 'M' 'I' 'T' 'J' 'C' 'H' 'Q' 'G' 'N' 'U' 'V' 'K' 'D' 'L' 'U' 'P' 'S' 'Z' 'Y'};
% General Parameters
%resetRandGen(subject_id);
fs = 24414; %letter sample rate
rms_amp = .01; %final normalization
letter_decibel = -10; %amplitude of letters in wheel; final stim normalized
odd_tone_decibel = -30; %amplitude of tone oddballs
odd_num_decibel = -30;
white_noise_decibel = -60;  %amplitude 
distance_sound = 5; %distance for stimuli to be played in HRTF
%bit rate of stimuli?

%amplitude modulator shifts amplitude of each wheel with AM_freq Hz; 0 for constant amplitude
AM_freq = [0 0 0 0 0 0 0 0]; %Hz rate of amplitude modulator elements for each wheel 0 for none
AM_pow =  [0 0 0 0 0 0 0 0]; %decibel of each AM for each corresponding wheel

%Parameters of block design
scale_type = 'whole'; %string 'whole' or 'diatonic'
target_letter = {'B'}; %one letter per block
tot_block = length(target_letter); % a block for each target letter
rep_block = 1;  % how many times each wheel will be looped for each letterblock
wheel_num = 3; %number of looped wheels each assigned a spatial location (WN) 3 if letters_wheel = 8
letters_wheel = 8; %letters per wheel each assigned a pentatonic pitch (LW)
total_letters = wheel_num * letters_wheel;
target_per_block = 2; % no. target oddballs in each letterblock must be greater than rep_blcok
play_wheel = [1 1 1 1 1]; %boolean array to include certain wheels for training trials
wheel_matrix = [7 8 9]; % number of letters in each wheel
tot_cyc = 10;
targ_cyc = 3;
wheel_time = 1.000; % how long each wheel will last in seconds
for i = 1:length(wheel_matrix)
    ILI_sec(i) = wheel_time / wheel_matrix(i);
end
ILI = ceil(ILI_sec .* fs);
IWI = ceil(ILI / wheel_num);
wheel_token_Hz = wheel_matrix / wheel_time;

%Timing/sample length parameters
% inter_wheel_sec = inter_wheel_msec(z) / 1000; %time (ms) between different wheel offsets
% inter_wheel = ceil(inter_wheel_sec * fs); %(IWI)
% %inter_letter_sec = 400 / 1000; %time (ms) between each letter in a wheel
% inter_letter_sec = wheel_num * inter_wheel_sec + inter_wheel_sec;  % creates blocks from IWI with no overlaps
% inter_letter = ceil(inter_letter_sec * fs); %convert to discrete samples (ILI)

postblock_sec = .5; %secs after letterblocks
postblock = ceil(postblock_sec * fs); 
preblock_prime_sec = 4.5; %secs to introduce primer letter
preblock = ceil(preblock_prime_sec * fs);
primer_start = 3000;  %sample # that primer letter will play in the preblock; must be less than preblock
letterblock = ceil(ILI * letters_wheel * tot_cyc + IWI * (wheel_num - 1)) + 15000; %rough sample length of each letterblock + extra space for last letter
tot_sample = preblock + letterblock + postblock; %total samples in each wavfile

for i = 1:tot_block  % each target letter assigned a block written to a specific wav file
    [ wheel_matrix, target_wheel_index, wheel_col, total_target_letters ] = generate_letter_matrix_wheel( letterArray, wheel_num, letters_wheel, target_letter, targ_cyc, tot_cyc); % returns cell array of wheel_num elements
    [pitch_wheel, angle_wheel, total_pitches, list_of_pitches] = pitch_angle_wheel(wheel_num, letters_wheel, tot_cyc, scale_type); %returns corresponding cell arrays
    final_stim = zeros(tot_sample, 2); % creates background track for each letter to be added on
    final_stim = final_stim + (10^(white_noise_decibel/20)) * randn(tot_sample, 2); %adds in white noise to background track
    primer_added = 0; %(re)sets whether primer has been added to each block 
    indexer_final = preblock; %delays each wheel by inter_wheel interval only refers to row for final_stim
    for j = 1:wheel_num 
        indexer = 1; %used for each wheel for wheel_track indexing; 
        wheel_track = zeros(letterblock, 2); %(re)initialize background track for each wheel
        for k = 1:tot_cyc %for each cycle of the individual wheel
            for l = 1:wheel_col %for each letter
                letter = wheel_matrix{j}{k, l}; %finds the letter in wheel_matrix cell
                pitch = pitch_wheel{j}{k, l}; %finds the pitch in pitch_wheel cell
                angle = angle_wheel{j}(k, l); %finds the angle in angle_wheel for each letter
                path = fullfile(letter_path, pitch, letter);
                [letter_sound, fs] = wavread(path);
                [L, R] = stimuliHRTF(letter_sound, fs, angle, distance_sound, K70_dir);
                letter_sound_proc = (10 ^(letter_decibel/20)) * [L R];
                foo = 1;
                for m = indexer: (indexer + length(letter_sound_proc) - 1)%adds in superposition to final_stim at indexer sample no
                    wheel_track(m, 1) = wheel_track(m, 1) + letter_sound_proc(foo, 1); 
                    wheel_track(m, 2) = wheel_track(m, 2) + letter_sound_proc(foo, 2);
                    foo = foo + 1;
                end
                if ~primer_added % if primer has not been added yet
                    if strcmp(letter, target_letter) %and this is the target letter
                            foo = 1;
                            for m = primer_start:(primer_start + length(letter_sound_proc) - 1)
                                final_stim(m, 1) = final_stim(m, 1) + letter_sound_proc(foo, 1); %adds primer in superposition to preblock
                                final_stim(m, 2) = final_stim(m, 2) + letter_sound_proc(foo, 2);
                                foo = foo + 1;
                            end
                            primer_added = 1;
                    end   
                end % adding primer
                indexer = indexer + ILI(j); %advances indexer to the next letter slot intra wheel
            end %for each letter
        end %for each cycle
        [final_wheel] = gen_new_envelope(wheel_track, AM_freq(j), AM_pow(j), fs);
        [rows, cols] = size(final_wheel);
        if play_wheel(j) %add to final_stim only if specified by play_wheel
            foo = 1;
            for m = indexer_final:(indexer_final + rows - 1)
                final_stim(m, 1) = final_stim(m, 1) + final_wheel(foo, 1); %adds each wheel in superposition to final_stim
                final_stim(m, 2) = final_stim(m, 2) + final_wheel(foo, 2); %adds each wheel in superposition to final_stim
                foo = foo + 1;
            end
        end
        indexer_final = indexer_final + IWI;
    end %for each wheel

   %stamps wav_name with each block labeled in WN, LW, IWI, ILI order specifying tone or dropped
   wav_name = fullfile(output_path, strcat('Block_', target_letter{i},'_WN_', int2str(wheel_num), '_LW_', int2str(letters_wheel), '_IWI_', int2str(IWI / fs), '_notargs_', int2str(targ_cyc),'_totcyc_', int2str(tot_cyc), '_', scale_type));
   final_stim = rms_amp * final_stim / sqrt(mean(mean(final_stim.^2)));
   wavwrite(final_stim, fs, wav_name);
if targ_cyc ~=  total_target_letters
    fprintf('Error in generate_letter_matrix_wheel')
end
end

    sound(final_stim, fs)
%    fprintf(wav_name)
% save(subject_id, 'target_oddball_times', 'append');


 