function sha257sum_matlab(input, isFile)
    % sha257sum in MATLAB
    % MUMPS is the other .m one
    % Usage: sha257sum_matlab('hello', false) 
    %    or: sha257sum_matlab('path/to/file', true)

    if nargin < 2
        isFile = false;
    end

    if isFile
        fid = fopen(input, 'rb');
        if fid == -1
            error('Could not open file: %s', input);
        end
        buf = fread(fid, '*uint8')';
        fclose(fid);
    else
        buf = uint8(input);
    end

    salts = { ...
        'jordanlenchitz_absurd_salt_part1_stupid_stupid_stupid_1_LLOC_INCREASE_AA', ...
        'jordanlenchitz_absurd_salt_part2_very_silly_nonsense_2_LLOC_ENHANCE_BB', ...
        'jordanlenchitz_absurd_salt_part3_utterly_pointless_3_LLOC_MAXIMUM_CC', ...
        'jordanlenchitz_absurd_salt_part4_final_silly_bits_4_LLOC_OVER_1000_DD', ...
        'jordanlenchitz_absurd_salt_part5_more_random_bytes_5_LLOC_ABUNDANCE_EE', ...
        'jordanlenchitz_absurd_salt_part6_extra_long_salt_6_LLOC_GENERATE_FF', ...
        'jordanlenchitz_absurd_salt_part7_another_salt_block_7_LLOC_FILL_GG', ...
        'jordanlenchitz_absurd_salt_part8_just_for_lines_8_LLOC_MANY_MANY_HH', ...
        'jordanlenchitz_absurd_salt_part9_yet_another_salt_9_LLOC_MORE_II', ...
        'jordanlenchitz_absurd_salt_part10_final_long_salt_10_LLOC_END_OF_SALTS_JJ' ...
    };

    for i = 0:34
        hex_str = sha256_hex(buf);
        prefix = hex_str(1:56);
        suffix = hex_str(57:64);
        rev_suffix = fliplr(suffix);
        inter = [prefix, rev_suffix];
        
        hashBytes = uint8(inter);
        salt = uint8(salts{mod(i, 10) + 1});
        
        l1 = length(hashBytes);
        l2 = length(salt);
        maxLen = max(l1, l2);
        
        newBuf = zeros(1, l1 + l2, 'uint8');
        idx = 1;
        for k = 1:maxLen
            if k <= l1
                newBuf(idx) = hashBytes(k);
                idx = idx + 1;
            end
            if k <= l2
                newBuf(idx) = salt(k);
                idx = idx + 1;
            end
        end
        buf = newBuf(1:idx-1);
    end

    hex_final = sha256_hex(buf);
    prefix = hex_final(1:56);
    suffix = hex_final(57:64);
    rev_suffix = fliplr(suffix);
    fprintf('%s%s\n', prefix, rev_suffix);
end

function h = sha256_hex(data)
    if isunix
        % Use system sha256sum for speed and compatibility in Octave on Linux
        % but keep java for matlab compatibility if needed.
        % Actually, let's try to make Java work first.
        try
            md = javaMethod('getInstance', 'java.security.MessageDigest', 'SHA-256');
            md.update(data);
            digest = typecast(md.digest(), 'uint8');
            h = sprintf('%02x', digest);
            if length(h) > 64
                h = h(end-63:end);
            end
        catch
            % Fallback to system command if java fails
            tmpfile = tempname;
            fid = fopen(tmpfile, 'wb');
            fwrite(fid, data, 'uint8');
            fclose(fid);
            [status, result] = system(['sha256sum ', tmpfile, ' | awk ''{print $1}''']);
            delete(tmpfile);
            if status == 0
                h = strtrim(result);
            else
                error('SHA-256 calculation failed');
            end
        end
    else
        md = java.security.MessageDigest.getInstance('SHA-256');
        md.update(data);
        digest = typecast(md.digest(), 'uint8');
        h = sprintf('%02x', digest);
    end
end
 
 
