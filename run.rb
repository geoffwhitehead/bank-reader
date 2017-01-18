class Parser

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

    # holds all the translated account number
    $account_numbers = Array.new

    # characters
    $char_underscore = '_'
    $char_pipe = '|'
    $char_invalid = '?'

    # status codes
    $ERROR = 'ERR'
    $ILLEGAL = 'ILL'

    def self.seed

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

    def self.parse
        line_number = 1
        account_number = Array.new(9, Array.new(7))

        File.open($dir + $sample_filename, 'r').each_line do |line|
            #p line
            char_count = 1
            # seperate case for first line due to the spaces not signifying absense of char_pipes or char_underscores
            if line_number == 1
                line.each_char do |char| #for each character
                    if is_valid_index(char_count)
                        if is_valid_character(char)
                            #p get_index(char_count)
                            account_number[get_index(char_count)].push(1)
                        else
                            account_number[get_index(char_count)].push(0)
                        end
                    end
                    char_count += 1
                end

            elsif line_number == 4
                Struct.new('Account', :account_number, :raw_account_number)
                add_to_array(Struct::Account.new(convert_account_number(account_number), account_number.dup))
                account_number.fill('')
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
        perform_error_checking()
        #print()
    end

    #
    def self.get_index(index)
        return ((index / 3.to_f).ceil) - 1
    end

    # prints out all the account numbers and their associated status codes
    def self.print
        $account_numbers.each do |account|
            #string = ''
            account.account_number.each do |d| string << d end
            #p string + ' ' + get_status(account).to_s
            #p account.raw_account_number
        end
        correct_invalid_char([1,0,0,1,1,1,1])
    end

    # convert an array of binary strings to a single 9 digit account string and return.
    def self.convert_account_number(raw_account_array)
        binary_account_number = Array.new

        raw_account_array.each do |raw_number|
            binary_account_number.push(decipher_number(raw_number))
        end

        #p do_checksum(binary_account_number)
        return binary_account_number
    end

    # add an account struct to the accounts array
    def self.add_to_array(account)
        $account_numbers.push(account)
    end

    # takes an account number 9 digit string and performs a checksum. Returns
    # true if passes.
    def self.do_checksum(binary_account_number)

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
        #p raw_number
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
    def self.get_status(account)
        return $ILLEGAL if account.account_number.include? $char_invalid
        return $ERROR if do_checksum(account.account_number) == false
    end

    def self.perform_error_checking
        $account_numbers.each
    end

    def self.correct_invalid_char(binary_digit)
        matches = 0
        index_matches = Array.new

        binary_digit.each_with_index do |bit, index|
            binary_digit[index] ^= 1
            #p binary_digit
            $masks.each do |mask, index|
                if mask == binary_digit
                    matches += 1
                    index_matches.push(index)
                end
            end
            binary_digit[index] ^= 1

        end
        p 'matches->'
        p matches
        p 'indexes ->'
        p index_matches
        a = 1
        a ^= 1
        a ^= 1
        a ^= 1
        p a


    end


end
