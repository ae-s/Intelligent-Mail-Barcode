#!/usr/bin/ruby

# Cribbed from the specification available at
# https://ribbs.usps.gov/intelligentmail_mailpieces/documents/tech_guides/SPUSPSG.pdf

class IMBarcode
  attr_reader :binary
  def initialize(code_id,
                 service_id,
                 mailer_id,
                 serial,
                 zip_zone = nil,
                 zip_route = nil,
                 zip_point = nil)

    @code_id = code_id
    @service_id = service_id
    @mailer_id = mailer_id
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

    binary, code_j = binary.divmod(636)
    binary, code_i = binary.divmod(1365)
    binary, code_h = binary.divmod(1365)
    binary, code_g = binary.divmod(1365)
    binary, code_f = binary.divmod(1365)
    binary, code_e = binary.divmod(1365)
    binary, code_d = binary.divmod(1365)
    binary, code_c = binary.divmod(1365)
    code_a, code_b = binary.divmod(1365)

    code_j *= 2
    if (check & 0x400)
      code_a += 659
    end

    printf("%d %d %d %d %d %d %d %d %d %d\n",
           code_a, code_b, code_c, code_d, code_e,
           code_f, code_g, code_h, code_i, code_j);

  end

  ## TODO translate the CRC code on page 24
  def crc(data, len=102)
    return 4;
  end
end
