#!/usr/bin/ruby

# Cribbed from the specification available at
# https://ribbs.usps.gov/intelligentmail_mailpieces/documents/tech_guides/SPUSPSG.pdf

require 'codeword.rb'

class IMBarcode
  include USPScode
  attr_reader :binary
  def initialize(code_id,
                 service_id,
                 mailer_id,
                 serial,
                 zip_zone = nil,
                 zip_route = nil,
                 zip_point = nil)

    # [[:digit:]][01234]
    @code_id = code_id

    # [[:digit:]]{3}
    @service_id = service_id

    # 000000000 - 999999999
    # or
    # 000000 - 999999
    @mailer_id = mailer_id

    # 000000 - 999999
    # or
    # 000000000 - 999999999
    @serial = serial

    if (zip_zone == nil)
      # No zipcode given
      binary = 0
    elsif ( (zip_zone != nil) and (zip_route == nil) )
      # 5-digit zipcode given
      binary = zip_zone
      binary += 1
    elsif ( (zip_zone != nil) and (zip_route != nil) and (zip_point == nil) )
      # 9-digit zipcode given
      binary = zip_zone
      binary *= 10000
      binary += zip_route
      binary += 100000 + 1
    else
      # 11-digit zipcode given
      binary = zip_zone
      binary *= 10000
      binary += zip_route
      binary *= 100
      binary += zip_point
      binary += 1000000000 + 100000 + 1
    end

    binary *= 10
    binary += (@code_id / 10)

    binary *= 5
    binary += (@code_id % 10)

    for i in 2.downto(0) do
      binary *= 10
      binary += (@service_id / (10 ** i)) % 10
    end

    if (@mailer_id < 899999)
      # Short mailer ID and long serial number, for high-volume
      # mailers.
      for i in 5.downto(0) do
        binary *= 10
        binary += (@mailer_id / (10 ** i)) % 10
      end
      for i in 8.downto(0) do
        binary *= 10
        binary += (@serial / (10 ** i)) % 10
      end
    else
      # Long mailer ID and short serial number, for low-volume
      # mailers.
      for i in 8.downto(0) do
        binary *= 10
        binary += (@mailer_id / (10 ** i)) % 10
      end
      for i in 5.downto(0) do
        binary *= 10
        binary += (@serial / (10 ** i)) % 10
      end
    end

    @binary = binary
    printf("Encoded bitstring: %X\n", @binary)

    check = crc(binary, 102)

    # Divide out into codewords
    binary, code_j = binary.divmod(636)
    binary, code_i = binary.divmod(1365)
    binary, code_h = binary.divmod(1365)
    binary, code_g = binary.divmod(1365)
    binary, code_f = binary.divmod(1365)
    binary, code_e = binary.divmod(1365)
    binary, code_d = binary.divmod(1365)
    binary, code_c = binary.divmod(1365)
    code_a, code_b = binary.divmod(1365)

    # Alter codeword J for orientation information
    code_j *= 2

    check = sprintf('%011b', check)
    print "Checksum is #{check}\n"

    check = check.rjust(11, '0').reverse
    print "Checksum is #{check}\n"

    # Stow bit 11 of the checksum in codeword A
    if (check[10].chr == '1')
      code_a += 659
    end

    printf("codewords -\n% 4d\t% 4d\t% 4d\t% 4d\t% 4d\t% 4d\t% 4d\t% 4d\t% 4d\t% 4d\n" +
                          "   A\t   B\t   C\t   D\t   E\t   F\t   G\t   H\t   I\t   J\n",
           code_a, code_b, code_c, code_d, code_e,
           code_f, code_g, code_h, code_i, code_j)

    bitstring = make_symbol(code_a, check[0].chr == '1') +
      make_symbol(code_b, check[1].chr == '1') +
      make_symbol(code_c, check[2].chr == '1') +
      make_symbol(code_d, check[3].chr == '1') +
      make_symbol(code_e, check[4].chr == '1') +
      make_symbol(code_f, check[5].chr == '1') +
      make_symbol(code_g, check[6].chr == '1') +
      make_symbol(code_h, check[7].chr == '1') +
      make_symbol(code_i, check[8].chr == '1') +
      make_symbol(code_j, check[9].chr == '1')

    print bitstring, "\n";
    print perturb(bitstring), "\n";

  end

  ## TODO translate the CRC code on page 24
  def crc(data, len=102)
    return 0x751;
  end

  # This is the penultimate encoding step.  The ten codewords each
  # contain 11 bits of information, and are expanded to a 13-bit
  # representation.  From the Specification:

  ## Each Codeword shall be converted from a decimal value ... to a
  ## 13-bit Character.
  ##
  ## If the Codeword has a value from 0 to 1286, the Character shall
  ## be determined by indexing into Table I, in Appendix E, using the
  ## Codeword.
  ##
  ## If the Codeword has a value from 1287 to 1364, the Character
  ## shall be determined by indexing into Table II, in Appendix E,
  ## using the Codeword reduced by 1287 (result from 0 to 77).

  # These tables are produced by a fragment of C code which increments
  # through all possible 13-bit numbers, plucking out only the numbers
  # which satisfy the M-of-13-bits-set condition.

  # It does this in an unusual order: a M-of-13 codeword is produced
  # and emitted.  Then it is bit-order-reversed and emitted again.  If
  # the codeword is palindromic, it is put at the end of the table.

  # Table I contains 5-of-13 codewords, while Table II contains
  # 2-of-13.  This is a concatenation of both of them.

  # I have no idea why this particular representation was chosen.

  def reflected_m_of_n(code_in)
    if (code_in > CODEWORDS.length)
      throw Exception.new("Code #{code_in} is out of range for this barcode symbology")
    end

    return sprintf("%b", CODEWORDS[code_in]).rjust(13, '0')
  end

  # If the corresponding CRC bit for this codeword is set, invert all
  # the bits.  Thus, the output from this routine is a 13-character
  # string consisting of 0s and 1s.
  #
  # There will be exactly 2, 5, 8, or 11 bits set in the result.

  def make_symbol(codeword, invert=false)
    symbol = reflected_m_of_n(codeword)

    if (invert)
      symbol.tr!('01', '10')
    end

    print "Codeword #{codeword} becomes #{symbol} invert=#{invert}\n"

    return symbol.reverse
  end


  # This defines the perturbation by which the barcode symbols are
  # rearranged.  It is presented in the form of a pair of arrays.
  #
  # The first array, descender[], is the bit to insepect to determine
  # the presence or absence of a descender.
  #
  # The second array, ascender[], is likewise, but for an ascender.

  # The derivation of this sequence is not given.

  def perturb(bitstring)

    descender = [93, 23, 129, 70, 113, 1, 31, 56, 81, 48, 76, 109,
                 127, 92, 45, 3, 82, 14, 101, 52, 80, 115, 125, 32,
                 66, 25, 94, 73, 58, 43, 108, 102, 78, 6, 27, 74, 63,
                 122, 42, 7, 16, 88, 111, 37, 8, 54, 75, 120, 83, 99,
                 65, 29, 90, 50, 112, 69, 18, 118, 107, 91, 59, 12,
                 35, 86, 49]

    ascender = [55, 0, 34, 89, 40, 77, 21, 128, 114, 97, 17, 38, 2,
                85, 61, 110, 33, 126, 67, 47, 4, 13, 51, 98, 62, 87,
                104, 124, 36, 5, 72, 22, 123, 60, 41, 116, 79, 95, 15,
                26, 53, 44, 121, 71, 103, 105, 39, 9, 30, 20, 57, 10,
                119, 19, 100, 11, 28, 64, 84, 46, 96, 24, 117, 68,
                106]

    barcode = " " * 65

    bitstring = bitstring.rjust(130, '0')

    printf("Perturbing:\n%s\n%s\n", bitstring, "-" * 130)

    for i in 0..(descender.size()-1)
      printf("   perturbing % 3d @% 4d /% 4d = %d/%d", i, ascender[i], descender[i], bitstring[ascender[i]].chr, bitstring[descender[i]].chr)
      down = bitstring[descender[i]].chr
      up = bitstring[ascender[i]].chr

      case (up + down)
      when "00"  # tracker bar
        barcode[i] = "T"
      when "10"  # ascender bar
        barcode[i] = "A"
      when "01"  # descender bar
        barcode[i] = "D"
      when "11"  # full bar
        barcode[i] = "F"
      end
    printf(" = %c\n", barcode[i])
    end
    return barcode
  end
end


