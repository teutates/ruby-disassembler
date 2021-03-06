def jumps opcode, instruction_address
  case opcode
    when 'e8' # call
      operator = 'CALL'

      #take starting address plus 0x5 (length of instruction) + value in next 4 bytes
      mem = "#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}".hex
      bits = mem.to_s(2)
      while bits.length !=32
        bits.to_s.insert(0, '0') # pad the left with zeros for no false negatives
      end
      if bits[0..0] == '1' # must be a backwards call
        mem = "#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}" # rewrite mem as neg
        mem = to_signed 32, mem
        address = instruction_address.to_i + 5 + mem
        @labels << address.to_s(16)
        return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 5]
      else # must be a positive call
        address = instruction_address.to_i + 5 + mem
        @labels << address.to_s(16)
        return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 5]
      end
    when 'e9'
      operator = 'JMP'
      #take starting address plus 0x5 (length of instruction) + value in next 4 bytes
      mem = "#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}".hex
      bits = mem.to_s(2)
      while bits.length !=32
        bits.to_s.insert(0, '0') # pad the left with zeros for no false negatives
      end
      if bits[0..0] == '1' # must be a backwards call
        mem = "#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}" # rewrite mem as neg
        mem = to_signed 32, mem
        address = instruction_address.to_i + 5 + mem
        return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 5]
      else # must be a positive call
        address = instruction_address.to_i + 5 + mem
        return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 5]
      end
    when '74'
      operator = 'JZ'
      mem = "#{@hex[instruction_address + 1]}".hex
      bits = mem.to_s(2)
      while bits.length != 8
        bits.to_s.insert(0, '0') # pad the left with zeros for no false negatives
      end
      if bits[0..0] == '1' # must be a backwards call
        mem = "#{@hex[instruction_address + 1]}" # rewrite mem as neg
        mem = to_signed 8, mem
        address = instruction_address.to_i + 2 + mem
        @labels << address.to_s(16)
        return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 2]
      else # must be a positive call
        address = instruction_address.to_i + 2 + mem
        @labels << address.to_s(16)
        return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 2]
      end
    when '75'
      operator = 'JNZ'
      mem = "#{@hex[instruction_address + 1]}".hex
      bits = mem.to_s(2)
      while bits.length != 8
        bits.to_s.insert(0, '0') # pad the left with zeros for no false negatives
      end
      if bits[0..0] == '1' # must be a backwards call
        mem = "#{@hex[instruction_address + 1]}" # rewrite mem as neg
        mem = to_signed 8, mem
        address = instruction_address.to_i + 2 + mem
        @labels << address.to_s(16)
        return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 2]
      else # must be a positive call
        address = instruction_address.to_i + 2 + mem
        @labels << address.to_s(16)
        return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 2]
      end

  end

  return["Jumps Invalid opcode:#{opcode}", false, 1]
end


# handles the special cases of default EAX in one of the src or dest
def default_eax opcode, instruction_address
  case opcode
    #handle ADD EAX, Imm32
    when '05'
      mem = "0x#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}"
      return ["ADD \tEAX, #{mem}", true, 5]
    when '25'
      mem = "0x#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}"
      return ["AND \tEAX, #{mem}", true, 5]
    when '0d'
      mem = "0x#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}"
      return ["OR \tEAX, #{mem}", true, 5]
    when '3d'
      mem = "0x#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}"
      return ["CMP \tEAX, #{mem}", true, 5]
    when '1d'
      mem = "0x#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}"
      return ["SBB \tEAX, #{mem}", true, 5]
    when 'a9'
      mem = "0x#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}"
      return ["TEST \tEAX, #{mem}", true, 5]
    when '35'
      mem = "0x#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}"
      return ["XOR \tEAX, #{mem}", true, 5]
  end
  return["Invalid opcode:#{opcode}", false, 1]
end

# handles the cases where the there are multibyte opcodes
def multibyte_opcodes opcode, instruction_address
  case opcode
    when '0f'
      bswap = %w(c8 c9 ca cb cc cd ce cf)
      if bswap.include?(@hex[instruction_address+1])
        instruction = (@hex[instruction_address+1].hex - 200)
        return ["BSWAP #{@operand[instruction]}", true, 2]
      end
      next_byte = @hex[instruction_address+1]
      case next_byte
        when 'af'
          instruction_address += 1
          modrm = @hex[instruction_address + 1]
          operands = @bits[instruction_address + 1]
          mod = operands[0..1]
          operator = 'IMUL'
          case mod
            when '00'
              @zz.each_with_index do |column, i|
                if column.include?(modrm)
                  index = column.index(modrm)
                  if index == 5
                    mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                    return ["#{operator} \t#{@operand[i]}, [0x#{mem}]", true, 7]
                  else
                    return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}]", true, 3]
                  end
                end
              end
            when '01'
              @zo.each_with_index do |column, i|
                if column.include?(modrm)
                  index = column.index(modrm)
                  mem = "#{@hex[instruction_address + 2]}"
                  return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}+0x#{mem}]", true, 4]
                end
              end
            when '10'
              @oz.each_with_index do |column, i|
                if column.include?(modrm)
                  index = column.index(modrm)
                  mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                  return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}+0x#{mem}]", true, 7]
                end
              end
            when '11'
              @oo.each_with_index do |column, i|
                if column.include?(modrm)
                  index = column.index(modrm)
                  # test with add (03 c0) should be ADD eax, eax
                  return ["#{operator} \t#{@operand[i]}, #{@operand[index]}", true, 3]
                end
              end
          end
        when '84'
          instruction_address += 1
          operator = 'JZ'
          #take starting address plus 0x5 (length of instruction) + value in next 4 bytes
          mem = "#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}".hex
          bits = mem.to_s(2)
          while bits.length !=32
            bits.to_s.insert(0, '0') # pad the left with zeros for no false negatives
          end
          if bits[0..0] == '1' # must be a backwards call
            mem = "#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}" # rewrite mem as neg
            mem = to_signed 32, mem
            address = instruction_address.to_i + 5 + mem
            @labels << address.to_s(16)
            return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 6]
          else # must be a positive call
            address = instruction_address.to_i + 5 + mem
            @labels << address.to_s(16)
            return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 6]
          end
        when '85'
          instruction_address += 1
          operator = 'JNZ'
          #take starting address plus 0x5 (length of instruction) + value in next 4 bytes
          mem = "#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}".hex
          bits = mem.to_s(2)
          while bits.length !=32
            bits.to_s.insert(0, '0') # pad the left with zeros for no false negatives
          end
          if bits[0..0] == '1' # must be a backwards call
            mem = "#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}" # rewrite mem as neg
            mem = to_signed 32, mem
            address = instruction_address.to_i + 5 + mem
            @labels << address.to_s(16)
            return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 6]
          else # must be a positive call
            address = instruction_address.to_i + 5 + mem
            @labels << address.to_s(16)
            return ["#{operator} \tLabel_0x#{address.to_s(16)}", true, 6]
          end
        when 'b7'
          instruction_address += 1
          case @hex[instruction_address + 1]
            when 'c8'
              operator = 'MOVZX'
              return ["#{operator} ECX, AX", true, 3]
          end
      end
    when 'f3' #popcnt
      next_byte = @hex[instruction_address+1]
      case next_byte
        when '0f'
          next_byte = @hex[instruction_address+2]
          case next_byte
            when 'b8'
              instruction_address += 2
              modrm = @hex[instruction_address + 1]
              operands = @bits[instruction_address + 1]
              mod = operands[0..1]
              operator = 'POPCNT'
              case mod
                when '00'
                  @zz.each_with_index do |column, i|
                    if column.include?(modrm)
                      index = column.index(modrm)
                      if index == 5
                        mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                        return ["#{operator} \t#{@operand[i]}, [0x#{mem}]", true, 8]
                      else
                        return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}]", true, 4]
                      end
                    end
                  end
                when '01'
                  @zo.each_with_index do |column, i|
                    if column.include?(modrm)
                      index = column.index(modrm)
                      mem = "#{@hex[instruction_address + 2]}"
                      return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}+0x#{mem}]", true, 5]
                    end
                  end
                when '10'
                  @oz.each_with_index do |column, i|
                    if column.include?(modrm)
                      index = column.index(modrm)
                      mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                      return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}+0x#{mem}]", true, 8]
                    end
                  end
                when '11'
                  @oo.each_with_index do |column, i|
                    if column.include?(modrm)
                      index = column.index(modrm)
                      # test with add (03 c0) should be ADD eax, eax
                      return ["#{operator} \t#{@operand[i]}, #{@operand[index]}", true, 4]
                    end
                  end
              end
          end
        when 'a7'
          return ['REPNE CMPS', true, 2]
      end
      return["Invalid opcode:#{opcode}", false, 1]
  end
end

# handles the cases where the opcode has a /digit
def extended_opcodes opcode, instruction_address
  operands = @bits[instruction_address + 1]
  mod = operands[0..1]
  reg = operands[2..4]
  rm = operands[5..7]
  modrm = @hex[instruction_address + 1]
  operator = ''
  case opcode
    when '81'
      case reg
        when '000'
          operator = 'ADD'
        when '100'
          operator = 'AND'
        when '001'
          operator = 'OR'
        when '111'
          operator = 'CMP'
        when '011'
          operator = 'SBB'
        when '110'
          operator = 'XOR'
      end
      case mod #seven possibilities 000 - 111 for r/m
        when '00'
          @zz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              if index == 5
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                next_mem = "#{@hex[instruction_address + 9]}#{@hex[instruction_address + 8]}#{@hex[instruction_address + 7]}#{@hex[instruction_address + 6]}"
                return ["#{operator} \t[0x#{mem}], 0x#{next_mem}", true, 10] # format should be operator [next 4 bytes of mem], next four bytes of mem: test 81 05 44 33 22 11 88 77 66 55 = add [11223344], 55667788
              else
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                return ["#{operator} \t[#{@operand[index]}], 0x#{mem}", true, 6] # format should be operator [reg], next 4 bytes: test with 81 00 44 33 22 11 = add [eax], 11223344
              end
            end
          end
        when '01'
          @zo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 2]}"
              next_mem = "#{@hex[instruction_address + 6]}#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}], 0x#{next_mem}", true, 7] # format should be operator [reg+1byte], next 4 bytes: test with 81 40 08 44 33 22 11 = add [eax+0x08], 0x11223344
            end
          end
        when '10'
          @oz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              next_mem = "#{@hex[instruction_address + 9]}#{@hex[instruction_address + 8]}#{@hex[instruction_address + 7]}#{@hex[instruction_address + 6]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}], 0x#{next_mem}", true, 10] # format should be operator [reg+1byte], next 8 bytes: test with 81 80 44 33 22 11 88 77 66 55 = add dword [eax+0x11223344], 0x55667788
            end
          end
        when '11'
          @oo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              return ["#{operator} \t#{@operand[index]}, 0x#{mem}", true, 6] # format should be operator [reg+8bytes], next 8 bytes: test with 81 C0 44 33 22 11 = add eax, 0x11223344
            end
          end
      end
    when 'f7'
      case reg
        when '010'
          operator = 'NOT'
        when '111'
          operator = 'IDIV'
        when '101'
          operator = 'IMUL'
        when '100'
          operator = 'MUL'
        when '011'
          operator = 'NEG'
        when '000'
          operator = 'TEST'
          case mod # rm can be 0..7
            when '00'
              @zz.each_with_index do |column, i|
                if column.include?(modrm)
                  index = column.index(modrm)
                  if index == 5
                    mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                    next_mem = "#{@hex[instruction_address + 9]}#{@hex[instruction_address + 8]}#{@hex[instruction_address + 7]}#{@hex[instruction_address + 6]}"
                    return ["#{operator} \t[0x#{mem}], 0x#{next_mem}", true, 10] # format should be operator [next 4 bytes of mem]
                  else
                    mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                    return ["#{operator} \t[#{@operand[index]}], 0x#{mem}", true, 6] # format should be operator [reg], next 4 bytes: test with 81 00 44 33 22 11 = add [eax], 11223344
                  end
                end
              end
            when '01'
              @zo.each_with_index do |column, i|
                if column.include?(modrm)
                  index = column.index(modrm)
                  mem = "#{@hex[instruction_address + 2]}"
                  next_mem = "#{@hex[instruction_address + 6]}#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}"
                  return ["#{operator} \t[#{@operand[index]}+0x#{mem}], 0x#{next_mem}", true, 7] # format should be operator [reg+1byte],
                end
              end
            when '10'
              @oz.each_with_index do |column, i|
                if column.include?(modrm)
                  index = column.index(modrm)
                  mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                  next_mem = "#{@hex[instruction_address + 9]}#{@hex[instruction_address + 8]}#{@hex[instruction_address + 7]}#{@hex[instruction_address + 6]}"
                  return ["#{operator} \t[#{@operand[index]}+0x#{mem}], 0x#{next_mem}", true, 10] # format should be operator [reg+1byte], next 8 bytes: test with 81 80 44 33 22 11 88 77 66 55 = add dword [eax+0x11223344], 0x55667788
                end
              end
            when '11'
              @oo.each_with_index do |column, i|
                if column.include?(modrm)
                  index = column.index(modrm)
                  mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                  return ["#{operator} \t#{@operand[index]}, 0x#{mem}", true, 6] # format should be operator [reg+8bytes], next 8 bytes: test with 81 C0 44 33 22 11 = add eax, 0x11223344
                end
              end
          end
      end
      case mod # rm can be 0..7
        when '00'
          @zz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              if index == 5
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                return ["#{operator} \t[0x#{mem}]", true, 6] # format should be operator [next 4 bytes of mem]
              else
                return ["#{operator} \t[#{@operand[index]}]", true, 2] # format should be operator [reg], next 4 bytes: test with 81 00 44 33 22 11 = add [eax], 11223344
              end
            end
          end
        when '01'
          @zo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 2]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}]", true, 3] # format should be operator [reg+1byte],
            end
          end
        when '10'
          @oz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}]", true, 6] # format should be operator [reg+1byte], next 8 bytes: test with 81 80 44 33 22 11 88 77 66 55 = add dword [eax+0x11223344], 0x55667788
            end
          end
        when '11'
          @oo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              return ["#{operator} \t#{@operand[index]}", true, 2] # format should be operator [reg+8bytes], next 8 bytes: test with 81 C0 44 33 22 11 = add eax, 0x11223344
            end
          end
      end
    when '8f'
      case reg
        when '000'
          operator = 'POP'
      end
      case mod # rm can be 0..7
        when '00'
          @zz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              if index == 5
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                return ["#{operator} \t[0x#{mem}]", true, 6] # format should be operator [next 4 bytes of mem]
              else
                return ["#{operator} \t[#{@operand[index]}]", true, 2] # format should be operator [reg], next 4 bytes: test with 81 00 44 33 22 11 = add [eax], 11223344
              end
            end
          end
        when '01'
          @zo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 2]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}]", true, 3] # format should be operator [reg+1byte],
            end
          end
        when '10'
          @oz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}]", true, 6] # format should be operator [reg+1byte], next 8 bytes: test with 81 80 44 33 22 11 88 77 66 55 = add dword [eax+0x11223344], 0x55667788
            end
          end
        when '11'
          @oo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              return ["#{operator} \t#{@operand[index]}", true, 2] # format should be operator [reg+8bytes], next 8 bytes: test with 81 C0 44 33 22 11 = add eax, 0x11223344
            end
          end
      end
    when 'ff'
      case reg
        when '001'
          operator = 'DEC'
        when '110'
          operator = 'PUSH'
        when '000'
          operator = 'INC'
        when '100'
          operator = 'JMP'
      end
      case mod # rm can be 0..7
        when '00'
          @zz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              if index == 5
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                return ["#{operator} \t[0x#{mem}]", true, 6] # format should be operator [next 4 bytes of mem]
              else
                return ["#{operator} \t[#{@operand[index]}]", true, 2] # format should be operator [reg], next 4 bytes: test with 81 00 44 33 22 11 = add [eax], 11223344
              end
            end
          end
        when '01'
          @zo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 2]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}]", true, 3] # format should be operator [reg+1byte],
            end
          end
        when '10'
          @oz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}]", true, 6] # format should be operator [reg+1byte], next 8 bytes: test with 81 80 44 33 22 11 88 77 66 55 = add dword [eax+0x11223344], 0x55667788
            end
          end
        when '11'
          @oo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              return ["#{operator} \t#{@operand[index]}", true, 2] # format should be operator [reg+8bytes], next 8 bytes: test with 81 C0 44 33 22 11 = add eax, 0x11223344
            end
          end
      end
    when 'd1'
      case reg
        when '100'
          operator = 'SHL'
        when '111'
          operator = 'SAR'
        when '101'
          operator = 'SHR'
      end
      case mod # rm can be 0..7
        when '00'
          @zz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              if index == 5
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                return ["#{operator} \t[0x#{mem}], 0x1", true, 6] # format should be operator [next 4 bytes of mem]
              else
                return ["#{operator} \t[#{@operand[index]}], 0x1", true, 2] # format should be operator [reg], next 4 bytes: test with 81 00 44 33 22 11 = add [eax], 11223344
              end
            end
          end
        when '01'
          @zo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 2]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}], 0x1", true, 3] # format should be operator [reg+1byte],
            end
          end
        when '10'
          @oz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}], 0x1", true, 6] # format should be operator [reg+1byte], next 8 bytes: test with 81 80 44 33 22 11 88 77 66 55 = add dword [eax+0x11223344], 0x55667788
            end
          end
        when '11'
          @oo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              return ["#{operator} \t#{@operand[index]}, 0x1", true, 2] # format should be operator [reg+8bytes], next 8 bytes: test with 81 C0 44 33 22 11 = add eax, 0x11223344
            end
          end
      end
    when 'c7'
      case reg
        when '000'
          operator = 'MOV'
      end
      case mod # rm can be 0..7
        when '00'
          @zz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              if index == 5
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                next_mem = "#{@hex[instruction_address + 9]}#{@hex[instruction_address + 8]}#{@hex[instruction_address + 7]}#{@hex[instruction_address + 6]}"
                return ["#{operator} \t[0x#{mem}], 0x#{next_mem}", true, 10]
              else
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                return ["#{operator} \t[#{@operand[index]}], 0x#{mem}", true, 6] # test with add (01 30) should be add [eax], esi
              end
            end
          end
        when '01'
          @zo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 2]}"
              next_mem = "#{@hex[instruction_address + 6]}#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}], #{next_mem}", true, 7]
            end
          end

        when '10'
          @oz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              next_mem = "#{@hex[instruction_address + 9]}#{@hex[instruction_address + 8]}#{@hex[instruction_address + 7]}#{@hex[instruction_address + 6]}"
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}], #{next_mem}", true, 10]
            end
          end
        when '11'
      end
    when '83'
      case reg
        when '001'
          operator = 'OR'
        when '000'
          operator = 'ADD'
        when '100'
          operator = 'AND'
        when '111'
          operator = 'CMP'
        when '011'
          operator = 'SBB'
        when '101'
          operator = 'XOR'
      end
      case mod
        when '00'
          @zz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              if index == 5 # this is a memory reference not register test with add (01 05 78 56 34 12) should be [0x12345678], eax
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                next_mem = "#{@hex[instruction_address + 6]}"
                bits = next_mem.hex.to_s(2)
                while bits.length !=8
                  bits.to_s.insert(0, '0') # pad the left with zeros for no false negatives
                end
                if bits[0..0] == '1'
                  next_mem = "ffffff#{@hex[instruction_address + 6]}" #sign extend
                end
                return ["#{operator} \t[0x#{mem}], 0x#{next_mem}", true, 7]
              else
                mem = "#{@hex[instruction_address + 2]}"
                bits = mem.hex.to_s(2)
                while bits.length !=8
                  bits.to_s.insert(0, '0') # pad the left with zeros for no false negatives
                end
                if bits[0..0] == '1'
                  mem = "ffffff#{@hex[instruction_address + 2]}" #sign extend
                end
                return ["#{operator} \t[#{@operand[index]}], 0x#{mem}", true, 3]
              end
            end
          end
        when '01'
          @zo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 2]}"
              next_mem = "#{@hex[instruction_address + 3]}"
              bits = next_mem.hex.to_s(2)
              while bits.length !=8
                bits.to_s.insert(0, '0') # pad the left with zeros for no false negatives
              end
              if bits[0..0] == '1'
                next_mem = "ffffff#{@hex[instruction_address + 3]}" #sign extend
              end
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}], 0x#{next_mem}", true, 4] #test with add (01 40 78) should be add [eax+0x78], eax
            end
          end
        when '10'
          @oz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              next_mem = "#{@hex[instruction_address + 6]}"
              bits = next_mem.hex.to_s(2)
              while bits.length !=8
                bits.to_s.insert(0, '0') # pad the left with zeros for no false negatives
              end
              if bits[0..0] == '1'
                next_mem = "ffffff#{@hex[instruction_address + 6]}" #sign extend
              end
              return ["#{operator} \t[#{@operand[index]}+0x#{mem}], 0x#{next_mem}", true, 7] #test with add (01 80 78 56 34 12) should be add [eax+0x12345678], eax
            end
          end
        when '11'
          @oo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              next_mem = "#{@hex[instruction_address + 2]}"
              bits = next_mem.hex.to_s(2)
              while bits.length !=8
                bits.to_s.insert(0, '0') # pad the left with zeros for no false negatives
              end
              if bits[0..0] == '1'
                next_mem = "ffffff#{@hex[instruction_address + 2]}" #sign extend
              end
              return ["#{operator} \t#{@operand[index]}, 0x#{next_mem}", true, 3] #test with add (01 dc) should be add esp, ebx
            end
          end
      end
  end
  return ["extended opcodes, nothing caught", false, 1]
end


def single_byte opcode, instruction_address
  case opcode
    when '90' #handle nop
      return ["NOP", true, 1]
    when 'cb'
      return['RETF', true, 1]
    when 'c3'
      return['RETN', true, 1]
    when 'a4'
      return['MOVSB', true, 1]
    when 'a5'
      return['MOVSD', true, 1]
  end
  if %w(58 59 5a 5b 5c 5d 5e 5f).include?(opcode) # handle pop
    #its a +rd pop operation
    instruction = (opcode.hex - 88)
    return ["POP \t#{@operand[instruction]}", true, 1]
  end
  if %w(48 49 4a 4b 4c 4d 4e 4f).include?(opcode) # handle dec
    #its a +rd dec operation
    instruction = (opcode.hex - 72)
    return ["DEC \t#{@operand[instruction]}", true, 1]
  end
  if %w(50 51 52 53 54 55 56 57).include?(opcode) # handle push
    #its a +rd push operation
    instruction = (opcode.hex - 80)
    return ["PUSH \t#{@operand[instruction]}", true, 1]
  end
  if %w(40 41 42 43 44 45 46 47).include?(opcode) # handle inc
    #its a +rd inc operation
    instruction = (opcode.hex - 64)
    return ["INC \t#{@operand[instruction]}", true, 1]
  end
  if %w(b8 b9 ba bb bc bd be bf).include?(opcode) # handle mov
    #its a +rd inc operation
    instruction = (opcode.hex - 184)
    mem = "#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}"
    return ["MOV \t#{@operand[instruction]}, #{mem}", true, 5]
  end
  return ["single byte opcodes, nothing caught", false, 1]
end

def decode_modrm instruction_address, opcode, operator_override
  operands = @bits[instruction_address + 1]
  mod = operands[0..1]
  modrm = @hex[instruction_address + 1]
  instruction = @instructions[opcode]
  operator = instruction.operator
  case mod
    when '00'
      @zz.each_with_index do |column, i|
        if column.include?(modrm) and instruction.dest == 'r/m' and instruction.src == 'r' # if add r/m32, r32  = 01/r
          index = column.index(modrm)
          if index == 5 # this is a memory reference not register test with add (01 05 78 56 34 12) should be [0x12345678], eax
            mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
            return ["#{operator} \t[0x#{mem}],#{@operand[i]}", true, 6]
          else
            return ["#{operator} \t[#{@operand[index]}], #{@operand[i]}", true, 2] # test with add (01 30) should be add [eax], esi
          end
        end
        if column.include?(modrm) and instruction.dest == 'r' and instruction.src = 'r/m' # if add r32, r/m32 = 03/r
          index = column.index(modrm)
          if index == 5 # this is a memory reference not register test with add (03 05 78 56 34) should be add eax, [0x12345678]
            mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
            return ["#{operator} \t#{@operand[i]}, [0x#{mem}]", true, 6]
          else
            return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}]", true, 2] # test with add (01 06) should be add [esi], eax
          end
        end
      end
    when '01'
      @zo.each_with_index do |column, i|
        if column.include?(modrm) and instruction.dest == 'r/m' and instruction.src == 'r' # if add r/m32, r32  = 01/r
          index = column.index(modrm)
          mem = "#{@hex[instruction_address + 2]}"
          return ["#{operator} \t[#{@operand[index]}+0x#{mem}], #{@operand[i]}", true, 3] #test with add (01 40 78) should be add [eax+0x78], eax
        end
        if column.include?(modrm) and instruction.dest == 'r' and instruction.src = 'r/m' # if add r32, r/m32 = 03/r
          index = column.index(modrm)
          mem = "#{@hex[instruction_address + 2]}"
          return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}+0x#{mem}]", true, 3] # test with add (03 40 78) should be add eax,[eax+0x78]
        end
      end
    when '10'
      @oz.each_with_index do |column, i|
        if column.include?(modrm) and instruction.dest == 'r/m' and instruction.src == 'r' # if add r/m32, r32  = 01/r
          index = column.index(modrm)
          mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
          return ["#{operator} \t[#{@operand[index]}+0x#{mem}], #{@operand[i]}", true, 6] #test with add (01 80 78 56 34 12) should be add [eax+0x12345678], eax
        end
        if column.include?(modrm) and instruction.dest == 'r' and instruction.src = 'r/m' # if add r32, r/m32 = 03/r
          index = column.index(modrm)
          # test with add (03 8a 90 78 56 34) should be ADD ECX, [EDX+0x34567890]
          mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
          return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}+0x#{mem}]", true, 6]
        end
      end
    when '11'
      @oo.each_with_index do |column, i|
        if column.include?(modrm) and instruction.dest == 'r/m' and instruction.src == 'r' # if add r32, r/m32  = 01/r
          index = column.index(modrm)
          return ["#{operator} \t#{@operand[index]}, #{@operand[i]}", true, 2] #test with add (01 dc) should be add esp, ebx
        end
        if column.include?(modrm) and instruction.dest == 'r' and instruction.src = 'r/m' # if add r32, r/m32 = 03/r
          index = column.index(modrm)
          # test with add (03 c0) should be ADD eax, eax
          return ["#{operator} \t#{@operand[i]}, #{@operand[index]}", true, 2]
        end
      end
  end
  return["Invalid opcode:#{opcode}", false, 1]
end

# handles some special cases
def special_case opcode, instruction_address
  case opcode
    when '68'
      operator = 'PUSH'
      mem = "#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}"
      return ["#{operator} \t0x#{mem}", true, 5]
    when 'ca'
      operator = 'RETF'
      mem = "#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}"
      return ["#{operator} \t0x#{mem}", true, 3]
    when 'c2'
      operator = 'RETN'
      mem = "#{@hex[instruction_address + 2]}#{@hex[instruction_address + 1]}"
      return ["#{operator} \t0x#{mem}", true, 3]
    when '69' # handle IMUL r32, r/m32, imm32
      modrm = @hex[instruction_address + 1]
      operands = @bits[instruction_address + 1]
      mod = operands[0..1]
      operator = 'IMUL'
      case mod
        when '00'
          @zz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              if index == 5
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                next_mem = "#{@hex[instruction_address + 9]}#{@hex[instruction_address + 8]}#{@hex[instruction_address + 7]}#{@hex[instruction_address + 6]}"
                return ["#{operator} \t#{@operand[i]}, [0x#{mem}], 0x#{next_mem}", true, 10]
              else
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}], 0x#{mem}", true, 6]
              end
            end
          end
        when '01'
          @zo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 2]}"
              next_mem = "#{@hex[instruction_address + 6]}#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}"
              return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}+0x#{mem}], 0x#{next_mem} ", true, 7]
            end
          end
        when '10'
          @oz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              next_mem = "#{@hex[instruction_address + 9]}#{@hex[instruction_address + 8]}#{@hex[instruction_address + 7]}#{@hex[instruction_address + 6]}"
              return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}+0x#{mem}], 0x#{next_mem}", true, 10]
            end
          end
        when '11'
          @oo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              return ["#{operator} \t#{@operand[i]}, #{@operand[index]}, 0x#{mem}", true, 6]
            end
          end
      end
    when '8d'
      modrm = @hex[instruction_address + 1]
      operands = @bits[instruction_address + 1]
      mod = operands[0..1]
      operator = 'LEA'
      case mod
        when '00'
          @zz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              if index == 5
                mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
                return ["#{operator} \t#{@operand[i]}, [0x#{mem}]", true, 6]
              else
                return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}]", true, 2]
              end
            end
          end
        when '01'
          @zo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 2]}"
              return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}+0x#{mem}] ", true, 3]
            end
          end
        when '10'
          @oz.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              return ["#{operator} \t#{@operand[i]}, [#{@operand[index]}+0x#{mem}]", true, 6]
            end
          end
        when '11'
          @oo.each_with_index do |column, i|
            if column.include?(modrm)
              index = column.index(modrm)
              mem = "#{@hex[instruction_address + 5]}#{@hex[instruction_address + 4]}#{@hex[instruction_address + 3]}#{@hex[instruction_address + 2]}"
              return ["#{operator} \t#{@operand[i]}, #{@operand[index]}, 0x#{mem}", true, 6]
            end
          end
      end
  end
  return["Invalid opcode:#{opcode}", false, 1]
end

#takes length number of bits and string of hex; returns signed hex string https://www.ruby-forum.com/topic/138200
def to_signed length, hex
  mid = 2**(length-1)
  max_unsigned = 2**length
  do_signed = proc { |n| (n>=mid) ? n - max_unsigned : n }

  return do_signed[hex.to_i(16)]
end