class Parser


    require 'pry'

    # file locations
    $dir = '/Users/geoff.whitehead/Dropbox/Source/kata-bankOCR/';
    $sample_filename = 'sample.txt'

    # holds the binary format for every possible digit. These are compared against
    # when determining whether any strings are legal or not
    $masks = Hash.new
    $masks[0] = [1,1,0,1,1,1,1]
    $masks[1] = [0,0,0,1,0,0,1]
    $masks[2] = [1,0,1,1,1,1,0]
    $masks[3] = [1,0,1,1,0,1,1]
    $masks[4] = [0,1,1,1,0,0,1]
    $masks[5] = [1,1,1,0,0,1,1]
    $masks[6] = [1,1,1,0,1,1,1]
    $masks[7] = [1,0,0,1,0,0,1]
    $masks[8] = [1,1,1,1,1,1,1]
    $masks[9] = [1,1,1,1,0,1,1]

    # Struct for account number
    Struct.new('Account', :account_number, :raw_account_number, :amb)

    # characters
    $char_underscore = '_'
    $char_pipe = '|'
    $char_invalid = '?'

    # status codes
    $ERROR = 'ERR'
    $ILLEGAL = 'ILL'
    $AMBIGUOUS = 'AMB'

    def self.main
        account_numbers = Array.new
        parse(account_numbers, $dir + $sample_filename)
        p "performing error check"
        perform_error_checking(account_numbers)
        print(account_numbers)
    end

    def self.is_valid_index(index)
        valid_elements = Array[0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0]
        return true if valid_elements[index-1] == 1
        return false
    end

    def self.is_valid_character(char)
        return true if char == $char_underscore || char == $char_pipe
        return false
    end

    # takes a file and and array and populates the array with structs containing account numbers
    def self.parse(account_numbers, file)
        line_number = 1
        account_number = Array.new(9){Array.new()}
        File.open(file, 'r').each_line do |line|
            char_count = 1
            if line_number == 1
                line.each_char do |char| #for each character
                    if is_valid_index(char_count)
                        if is_valid_character(char)
                            account_number[get_index(char_count)].push(1)
                        else
                            account_number[get_index(char_count)].push(0)
                        end
                    end
                    char_count += 1
                end
            elsif line_number == 4

                account_numbers.push(Struct::Account.new(convert_account_number(account_number), account_number.dup))
                account_number = Array.new(9){Array.new()}
                line_number = 0 #increment to 1 at the end of the loop
            else
                line.each_char do |char|
                    if is_valid_character(char)
                        account_number[get_index(char_count)].push(1)
                    elsif char == ' '
                        account_number[get_index(char_count)].push(0)
                    end
                    char_count += 1
                end
            end
            line_number += 1
            char_count = 0
        end
    end

    def self.get_index(index)
        return ((index / 3.to_f).ceil) - 1
    end

    # prints out all the account numbers and their associated status codes
    def self.print(account_numbers)
        account_numbers.each do |account|
            amb_string_array = Array.new
            if account.amb.size > 0
                account.amb.each do |amb|
                    amb_string_array.push(amb.join(''))
                end
                p account.account_number.join('') + ' ' + get_status(account).to_s + ' ' + amb_string_array.to_s + ' ' + is_passing_checksum(account.account_number).to_s
            else
                p account.account_number.join('') + ' ' + get_status(account).to_s + ' ' + is_passing_checksum(account.account_number).to_s
            end
        end
    end

    # convert an array of binary strings to a single 9 digit account string and return.
    def self.convert_account_number(raw_account_array)
        binary_account_number = Array.new
        raw_account_array.each do |raw_number|
            binary_account_number.push(decipher_number(raw_number))
        end
        return binary_account_number
    end

    # takes an account number 9 digit string and performs a checksum. Returns
    # true if passes.
    def self.is_passing_checksum(binary_account_number)
        index = 1
        sum = 0
        binary_account_number.reverse.each do |digit|
            sum += (index * digit.to_i)
            index += 1
        end
        return true if sum % 11 == 0
        return false
    end

    # check the binary string against the masks and return the number the string represents
    def self.decipher_number(raw_number)
        mask_index = ''
        $masks.each do |index, mask|
            if raw_number == mask
                mask_index = index
            end
        end
        if mask_index == ''
            return $char_invalid
        else
            return mask_index.to_s
        end
    end

    # takes a 9 digit account number string and returns a status code depending
    # on the validity of the string
    def self.get_illegal_indexes(account)
        indexes = Array.new
        account.account_number.each_with_index do |digit, index|
            indexes.push(index) if digit == $char_invalid
        end
        return indexes
    end

    def self.is_erroneous(account)
        return !is_passing_checksum(account.account_number)
    end

    def self.get_status(account)
        return $AMBIGUOUS if account.amb.size > 0
        return $ILLEGAL if get_illegal_indexes(account).size > 0
        return $ERROR if is_erroneous(account)
    end

    # performs error checking on data by first trying to correct any invalid characters, then
    # trying to correct any invalid checksums
    def self.perform_error_checking(account_numbers)
        account_numbers.each do |acc|
            find_and_correct_illegal_chars(acc) # pass 1 - correct any illegal characters with only 1 combination
            alts = get_valid_alternatives(acc)
            if alts.size == 1
                acc.account_number = alts[0]
            else
                acc.amb = alts
            end

        end
    end

    # returns an array of alternative account numbers that have a valid checksum
    def self.get_valid_alternatives(account)

        valid_possibles = Array.new()

        if get_illegal_indexes(account).size == 0 && is_erroneous(account) # if there are no invalid chars but the checksum fails
            account.raw_account_number.each_with_index do |raw_number, index|
                matches = get_illegal_corrections(raw_number)
                matches.each do |match|
                    temp = account.account_number.dup
                    temp[index] = decipher_number(match)
                    if is_passing_checksum(temp)
                        valid_possibles.push(temp)
                    end
                end
            end
        end
        return valid_possibles
    end

    # loop through all the raw binary number in account number and check for corrections
    def self.find_and_correct_illegal_chars(account_number)
        get_illegal_indexes(account_number).each do |index|
            possible_corrections = get_illegal_corrections(account_number.raw_account_number[index])
            if possible_corrections.size == 1
                correct_account_number(account_number, index, possible_corrections[0])
            end
        end
    end

    # applies a change to the account number and raw account number
    def self.correct_account_number(account, index, raw_correction)
        account.raw_account_number[index] = raw_correction
        account.account_number[index] = decipher_number(raw_correction)
    end

    # iterates over a binary number representation (eg 1001111 != to any mask).
    # Returns possible masks based on one bit flip
    def self.get_illegal_corrections(binary_digit)
        matches = Array.new
        binary_digit.each_with_index do |bit, index|
            binary_digit[index] ^= 1
            $masks.each do |index,mask|


                if mask == binary_digit
                    matches.push(mask)
                end
            end
            binary_digit[index] ^= 1
        end
        return matches
    end
end
