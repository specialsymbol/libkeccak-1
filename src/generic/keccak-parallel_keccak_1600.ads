with Keccak.Generic_Parallel_Permutation_Parallel_Fallback;
with Keccak.Generic_Parallel_Permutation_Serial_Fallback;
with Keccak.Keccak_1600;
with Keccak.Keccak_1600.Rounds_24;
with Keccak.Keccak_1600.Rounds_12;
with Keccak.Types;
with Interfaces;

pragma Elaborate_All (Keccak.Generic_Parallel_Permutation_Parallel_Fallback);
pragma Elaborate_All (Keccak.Generic_Parallel_Permutation_Serial_Fallback);

--  @brief@
--  Defines procedures for running Keccak-f permutations in parallel for
--  2x, 4x, and 8x parallelism, as well as serial permutations.
--
--  @description@
--
--  This package must define the following types and procedures:
--    * Permute_S1_R12 - Serial Keccak-p[1600] permutation with 12 rounds.
--    * Permute_S1_R24 - Serial Keccak-p[1600] permutation with 24 rounds.
--
--  For 2x parallelism:
--    * Parallel_State_P2
--    * Init_P2
--    * Permute_All_P2_R12
--    * Permute_All_P2_R24
--    * XOR_Bits_Into_State_Separate_P2
--    * Extract_Bytes_P2
--
--  For 4x parallelism:
--    * Parallel_State_P4
--    * Init_P4
--    * Permute_All_P4_R12
--    * Permute_All_P4_R24
--    * XOR_Bits_Into_State_Separate_P4
--    * Extract_Bytes_P4
--
--  For 8x parallelism:
--    * Parallel_State_P8
--    * Init_P8
--    * Permute_All_P8_R12
--    * Permute_All_P8_R24
--    * XOR_Bits_Into_State_Separate_P8
--    * Extract_Bytes_P8
--
--  Any other declarations in this package are architecture-specific and should
--  not be relied upon.
package Keccak.Parallel_Keccak_1600
with SPARK_Mode => On
is

   ----------------------------------------------------------------------------
   -- Keccak-f[1600]x2

   --  No SIMD available on this architecture. Fall back to serial implementation.

   package KeccakF_1600_P2
   is new Keccak.Generic_Parallel_Permutation_Serial_Fallback
     (Permutation_State   => Keccak_1600.KeccakF_1600.Lane_Complemented_State,
      Init                => Keccak_1600.KeccakF_1600.Init,
      XOR_Bits_Into_State => Keccak_1600.KeccakF_1600_Lanes.XOR_Bits_Into_State,
      Extract_Bytes       => Keccak_1600.KeccakF_1600_Lanes.Extract_Bytes,
      State_Size          => 1600,
      Parallelism         => 2);

   subtype Parallel_State_P2 is KeccakF_1600_P2.Parallel_State;

   procedure Init_P2 (S : out KeccakF_1600_P2.Parallel_State)
                      renames KeccakF_1600_P2.Init;

   procedure XOR_Bits_Into_State_Separate_P2
     (S           : in out Parallel_State_P2;
      Data        : in     Types.Byte_Array;
      Data_Offset : in     Natural;
      Bit_Len     : in     Natural)
      renames KeccakF_1600_P2.XOR_Bits_Into_State_Separate;

   procedure XOR_Bits_Into_State_All_P2
     (S           : in out Parallel_State_P2;
      Data        : in     Types.Byte_Array;
      Bit_Len     : in     Natural)
      renames KeccakF_1600_P2.XOR_Bits_Into_State_All;

   procedure Extract_Bytes_P2
     (S           : in     Parallel_State_P2;
      Data        : in out Types.Byte_Array;
      Data_Offset : in     Natural;
      Byte_Len    : in     Natural)
      renames KeccakF_1600_P2.Extract_Bytes;

   ----------------------------------------------------------------------------
   -- Keccak-f[1600]x4

   --  No SIMD available on this architecture. Fall back to serial implementation.

   package KeccakF_1600_P4
   is new Keccak.Generic_Parallel_Permutation_Serial_Fallback
     (Permutation_State   => Keccak_1600.KeccakF_1600.Lane_Complemented_State,
      Init                => Keccak_1600.KeccakF_1600.Init,
      XOR_Bits_Into_State => Keccak_1600.KeccakF_1600_Lanes.XOR_Bits_Into_State,
      Extract_Bytes       => Keccak_1600.KeccakF_1600_Lanes.Extract_Bytes,
      State_Size          => 1600,
      Parallelism         => 4);

   subtype Parallel_State_P4 is KeccakF_1600_P4.Parallel_State;

   procedure Init_P4 (S : out KeccakF_1600_P4.Parallel_State)
                      renames KeccakF_1600_P4.Init;

   procedure XOR_Bits_Into_State_Separate_P4
     (S           : in out Parallel_State_P4;
      Data        : in     Types.Byte_Array;
      Data_Offset : in     Natural;
      Bit_Len     : in     Natural)
      renames KeccakF_1600_P4.XOR_Bits_Into_State_Separate;

   procedure XOR_Bits_Into_State_All_P4
     (S           : in out Parallel_State_P4;
      Data        : in     Types.Byte_Array;
      Bit_Len     : in     Natural)
      renames KeccakF_1600_P4.XOR_Bits_Into_State_All;

   procedure Extract_Bytes_P4
     (S           : in     Parallel_State_P4;
      Data        : in out Types.Byte_Array;
      Data_Offset : in     Natural;
      Byte_Len    : in     Natural)
      renames KeccakF_1600_P4.Extract_Bytes;

   ----------------------------------------------------------------------------
   -- Keccak-f[1600]x8

   --  No SIMD available on this architecture. Fall back to serial implementation.

   package KeccakF_1600_P8
   is new Keccak.Generic_Parallel_Permutation_Serial_Fallback
     (Permutation_State   => Keccak_1600.KeccakF_1600.Lane_Complemented_State,
      Init                => Keccak_1600.KeccakF_1600.Init,
      XOR_Bits_Into_State => Keccak_1600.KeccakF_1600_Lanes.XOR_Bits_Into_State,
      Extract_Bytes       => Keccak_1600.KeccakF_1600_Lanes.Extract_Bytes,
      State_Size          => 1600,
      Parallelism         => 8);

   subtype Parallel_State_P8 is KeccakF_1600_P8.Parallel_State;

   procedure Init_P8 (S : out KeccakF_1600_P8.Parallel_State)
                      renames KeccakF_1600_P8.Init;

   procedure XOR_Bits_Into_State_Separate_P8
     (S           : in out Parallel_State_P8;
      Data        : in     Types.Byte_Array;
      Data_Offset : in     Natural;
      Bit_Len     : in     Natural)
      renames KeccakF_1600_P8.XOR_Bits_Into_State_Separate;

   procedure XOR_Bits_Into_State_All_P8
     (S           : in out Parallel_State_P8;
      Data        : in     Types.Byte_Array;
      Bit_Len     : in     Natural)
      renames KeccakF_1600_P8.XOR_Bits_Into_State_All;

   procedure Extract_Bytes_P8
     (S           : in     Parallel_State_P8;
      Data        : in out Types.Byte_Array;
      Data_Offset : in     Natural;
      Byte_Len    : in     Natural)
      renames KeccakF_1600_P8.Extract_Bytes;


end Keccak.Parallel_Keccak_1600;
