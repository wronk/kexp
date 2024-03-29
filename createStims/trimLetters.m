function [ fs, trim_letter_path, letterEnvelope, mean_speaker_sample ] = trimLetters(letter_samples, letter_path, letterArray, pitches, force_recreate, speaker_list, version_num, speaker_amp_weights, shiftedLetters, env_instrNotes, default_fs);
% Writes all new letters with the specified sample length of letter_samples and saves into 
% folder trim_letter_path a subdirectory of letter_path

fs = [];
letterEnvelope = {};    
summed_letter_speaker = zeros(letter_samples, length(speaker_list));
mean_speaker_sample = zeros(3, 1);
for x = 1:length(speaker_list)
	fs_speaker = default_fs; % default letter sample rate
	if shiftedLetters
		input_letter_path = fullfile(letter_path, 'shiftedLetters', speaker_list{x});
		assert(exist(input_letter_path, 'dir'), 'Error: you must shift the letters using praat first before using this speaker')
	else
		input_letter_path = fullfile(letter_path, 'rawLetters', strcat(speaker_list{x}, '_manuallyTrim'));
	end
	trim_letter_path = fullfile(letter_path, 'finalShiftTrimLetters', int2str(letter_samples)); % needs to also include the speaker folders for force_recreate to work properly
	output_path = fullfile(trim_letter_path, speaker_list{x});
	if ((~exist(trim_letter_path, 'dir')) || force_recreate)
		letterSound = {};
		trimmedLetters = {};
		if shiftedLetters
			iterations = length(pitches.all);
		else
			iterations = 1;
		end
		for i= 1:iterations %loop through all possible semitones
			for j = 1:length(letterArray.alphabetic) %loop through all letters in each semitone dir
				if shiftedLetters
					fp = fullfile(input_letter_path, pitches.all{i});
				else
					fp = input_letter_path;
				end
				temp_fn = strcat(speaker_list{x}, '-', letterArray.alphabetic{j}, int2str(version_num), '-t', '.wav');
				if (strcmpi(speaker_list{x}, 'Original') || strcmpi(speaker_list{x}, 'male_trimmed') || strcmpi(speaker_list{x}, 'female'))
					fn = strcat(letterArray.alphabetic{j});
				elseif exist(fullfile(fp, temp_fn), 'file')
					fn = temp_fn;
				else
					fn = strcat(speaker_list{x}, '_', letterArray.alphabetic{j}, int2str(version_num), '.wav');
				end
				if (strcmpi(letterArray.alphabetic(j), 'Read') || strcmpi(letterArray.alphabetic(j), 'Space') || strcmpi(letterArray.alphabetic(j), 'Delete') || strcmpi(letterArray.alphabetic(j), 'Pause'))
					ff = fullfile(letter_path, 'rawLetters', 'kdm_manuallyTrim', strcat(letterArray.alphabetic{j}, '.wav'));
				else
					ff = fullfile(fp, fn); 
				end
				[letterSound{j}, fs_speaker, letterBits] = wavread(ff);  % letter wavs for each semitone
				if env_instrNotes
					letterEnvelope{j} = envelopeByLetter(letterSound{j}, letter_samples, fs_speaker); 
					% VISUALIZE:
					% plot(letterEnvelope{j})
					% hold on
					% plot(letterEnvelope{j}, 'r')
					% title(letterArray.alphabetic{j})
					% waitforbuttonpress
					% hold off
				end

				% CHANGE OVERALL AMPLITUDE OF INDIVIDUAL SPEAKERS
				letterSound{j} = speaker_amp_weights(x) .* letterSound{j};
			end

			% % % EXCEPTIONS 'C', 'W'
			%  All letters have been manually trimmed
			% c = letterSound{3}; % makes c more audible
			% [row, col] = size(c);
			% letterSound{3}=[1600; c]
			% plot(c)
			% waitforbuttonpress
			% letterSound{3}= c(1500: row, 1);
			% plot(letterSound{3})
			% title('letterSound')
			% waitforbuttonpress
			% size(letterSound{3});
			% w = letterSound{23};
			% % letterSound{23} = w(1:4200); % 'W' to "dub"

			% TRIM EACH LETTER 
			for j = 1:length(letterArray.alphabetic)
				letterVector = letterSound{j};
				trimmedLetters{j} = trimSoundVector(letterVector, fs_speaker, letter_samples, 1, 1);
				if shiftedLetters
					final_output_path = fullfile(output_path, pitches.all{i});
				else
					final_output_path = output_path;
				end
				createStruct(final_output_path);
				final_trimmedLetters{j} = normalizeSoundVector(trimmedLetters{j});
				% size(final_trimmedLetters{j})
				% size(summed_letter_speaker(:, x))
				pwr_est = final_trimmedLetters{j}.^2;
				size(pwr_est); % +++
				summed_letter_speaker(:, x) = summed_letter_speaker(:, x) + pwr_est;
				wavwrite(final_trimmedLetters{j}, fs_speaker, fullfile(final_output_path, strcat(letterArray.alphabetic{j}, '.wav')));
			end    
		end
	end
	% assert((fs_speaker == 16000), 'Error: incorrect wavread of letterSound')
	fs(x) = fs_speaker;

	% DETERMINE MEAN SAMPLE OF HIGHEST AMP. FOR EACH SPEAKER
	[~, mean_speaker_sample(x)] = max(summed_letter_speaker(:, x));
end
assert((all(fs == fs(1))), 'Error: not all sampling frequencies match') % check for equality fprintf(fs)
fs = fs(1); %change back into a singular value
end