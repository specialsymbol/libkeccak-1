-------------------------------------------------------------------------------
-- Copyright (c) 2016, Daniel King
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--     * Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
--     * The name of the copyright holder may not be used to endorse or promote
--       Products derived from this software without specific prior written
--       permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
-- THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------

with Ada.Command_Line;
with Timing;                        use Timing;
with Ada.Text_IO;
with Ada.Long_Float_Text_IO;
with Interfaces;                    use Interfaces;
with KangarooTwelve;
with Keccak.Parallel_Keccak_1600;
with Keccak.Generic_KangarooTwelve;
with Keccak.Generic_KeccakF;
with Keccak.Keccak_25;
with Keccak.Keccak_50;
with Keccak.Keccak_100;
with Keccak.Keccak_200;
with Keccak.Keccak_400;
with Keccak.Keccak_800;
with Keccak.Keccak_1600;
with Keccak.Types;
with Keccak.Generic_XOF;
with Keccak.Generic_Hash;
with Keccak.Generic_Duplex;
with Keccak.Keccak_1600;
with SHA3;
with SHAKE;
with RawSHAKE;

procedure Benchmark
is
   Benchmark_Data_Size_MiB : constant := 128; -- size of the benchmark data in MiB
   Repeat                  : constant := 10;  -- number of benchmark iterations
   
   -- A 1 MiB data chunk to use as an input to the algorithms.
   type Byte_Array_Access is access Keccak.Types.Byte_Array;
   Data_Chunk : Byte_Array_Access := new Keccak.Types.Byte_Array (1 .. Benchmark_Data_Size_MiB*1024*1024);
   
   package Cycles_Count_IO is new Ada.Text_IO.Modular_IO (Cycles_Count);
   
   
   procedure Print_Cycles_Per_Byte (Data_Size : in Natural;
                                    Cycles    : in Cycles_Count)
   is
      CPB : Long_Float;
      
   begin
      CPB := Long_Float (Cycles) / Long_Float (Data_Size);
      
      Ada.Long_Float_Text_IO.Put
        (Item => CPB,
         Fore => 0,
         Aft  => 2,
         Exp  => 0);
      
      Ada.Text_IO.Put (" cycles/byte");
      Ada.Text_IO.New_Line;
   end Print_Cycles_Per_Byte;
   
   
   procedure Print_Cycles (Cycles : in Cycles_Count)
   is
   begin
      Cycles_Count_IO.Put (Cycles, Width => 0);
      Ada.Text_IO.Put (" cycles");
      Ada.Text_IO.New_Line;
   end Print_Cycles;
   
   ----------------------------------------------------------------------------
   -- Hash_Benchmark
   --
   -- Generic procedure to run a benchmark for any hash algorithm (e.g. SHA3-224,
   -- Keccak-256, etc...).
   ----------------------------------------------------------------------------
   generic
       Name : String;
       with package Hash_Package is new Keccak.Generic_Hash(<>);
   procedure Hash_Benchmark;
   
   procedure Hash_Benchmark
   is
      Ctx   : Hash_Package.Context;
      Digest : Hash_Package.Digest_Type;
      
      Start_Time : Timing.Time;
      Cycles     : Cycles_Count;
      Min_Cycles : Cycles_Count := Cycles_Count'Last;
      
   begin
      Ada.Text_IO.Put (Name & ": ");
      
      for I in Positive range 1 .. Repeat loop
         Start_Measurement (Start_Time);
      
         Hash_Package.Init(Ctx);
         
         Hash_Package.Update(Ctx, Data_Chunk.all, Data_Chunk.all'Length*8);
         
         Hash_Package.Final(Ctx, Digest);
         
         Cycles := End_Measurement (Start_Time);
         
         if Cycles < Min_Cycles then
            Min_Cycles := Cycles;
         end if;
      end loop;
      
      Print_Cycles_Per_Byte (Data_Chunk.all'Length, Min_Cycles);
   end Hash_Benchmark;
   
   
   ----------------------------------------------------------------------------
   -- XOF_Benchmark
   --
   -- Generic procedure to run a benchmark for any XOF algorithm (e.g. SHAKE128,
   -- RawSHAKE256, etc...).
   ----------------------------------------------------------------------------
   generic
       Name : String;
       with package XOF_Package is new Keccak.Generic_XOF(<>);
   procedure XOF_Benchmark;
   
   procedure XOF_Benchmark
   is
      Ctx    : XOF_Package.Context;
      
      Start_Time : Timing.Time;
      Cycles     : Cycles_Count;
      Min_Cycles : Cycles_Count := Cycles_Count'Last;
      
   begin
      Ada.Text_IO.Put(Name & " (Absorbing): ");
      
      -- Benchmark Absorbing
      for I in Positive range 1 .. Repeat loop
         Start_MEasurement (Start_Time);
      
         XOF_Package.Init(Ctx);
         
         XOF_Package.Update(Ctx, Data_Chunk.all, Data_Chunk.all'Length*8);
         
         Cycles := End_Measurement (Start_Time);
         
         if Cycles < Min_Cycles then
            Min_Cycles := Cycles;
         end if;
      end loop;
      
      Print_Cycles_Per_Byte (Data_Chunk.all'Length, Min_Cycles);
      
      Min_Cycles := Cycles_Count'Last;
      
      Ada.Text_IO.Put(Name & " (Squeezing): ");
      
      -- Benchmark squeezing
      for I in Positive range 1 .. Repeat loop
         Start_Measurement (Start_Time);
      
         XOF_Package.Extract(Ctx, Data_Chunk.all);
         
         Cycles := End_Measurement (Start_Time);
         
         if Cycles < Min_Cycles then
            Min_Cycles := Cycles;
         end if;
      end loop;
      
      Print_Cycles_Per_Byte (Data_Chunk.all'Length, Min_Cycles);
   end XOF_Benchmark;
   
   ----------------------------------------------------------------------------
   -- Duplex_Benchmark
   --
   -- Generic procedure to run a benchmark for any Duplex algorithm.
   ----------------------------------------------------------------------------
   generic
      Name : String;
      Capacity : Positive;
      with package Duplex is new Keccak.Generic_Duplex(<>);
   procedure Duplex_Benchmark;
   
   procedure Duplex_Benchmark
   is
      Ctx : Duplex.Context;
      
      Out_Data : Keccak.Types.Byte_Array(1 .. 1600/8);
      
      Start_Time : Timing.Time;
      Cycles     : Cycles_Count;
      Min_Cycles : Cycles_Count := Cycles_Count'Last;
      
   begin
      Ada.Text_IO.Put(Name & ": ");
         
      Duplex.Init(Ctx, Capacity);
      
      for I in Positive range 1 .. Repeat loop
         Start_Measurement (Start_Time);
         
         Duplex.Duplex(Ctx,
                       Data_Chunk.all(1 .. Duplex.Rate_Of(Ctx)/8),
                       Duplex.Rate_Of(Ctx) - Duplex.Min_Padding_Bits,
                       Out_Data(1 .. Duplex.Rate_Of(Ctx)/8),
                       Duplex.Rate_Of(Ctx) - Duplex.Min_Padding_Bits);
         
         Cycles := End_Measurement (Start_Time);
         
         if Cycles < Min_Cycles then
            Min_Cycles := Cycles;
         end if;       
      end loop;
      
      Print_Cycles (Min_Cycles);
   
   end Duplex_Benchmark;
   
   ----------------------------------------------------------------------------
   -- KeccakF_Benchmark
   --
   -- Generic procedure to run a benchmark for a KeccakF permutation.
   ----------------------------------------------------------------------------
   generic
      Name : String;
      type State_Type is private;
      with procedure Init (A : out State_Type);
      with procedure Permute(A : in out State_Type);
   procedure KeccakF_Benchmark;
   
   procedure KeccakF_Benchmark
   is
      package Duration_IO is new Ada.Text_IO.Fixed_IO(Duration);
      package Integer_IO is new Ada.Text_IO.Integer_IO(Integer);
            
      State : State_Type;
      
      Start_Time : Timing.Time;
      Cycles     : Cycles_Count;
      Min_Cycles : Cycles_Count := Cycles_Count'Last;
      
      Num_Iterations : Natural := 1_000_000;
      
   begin
      Ada.Text_IO.Put(Name & ": ");
      
      Init(State);
      
      for I in Positive range 1 .. Num_Iterations loop
         Start_Measurement (Start_Time);
         
         Permute(State);
         
         Cycles := End_Measurement (Start_Time);
         
         if Cycles < Min_Cycles then
            Min_Cycles := Cycles;
         end if;
      end loop;
      
      Print_Cycles (Min_Cycles);
      
   end KeccakF_Benchmark;
   
   ----------------------------------------------------------------------------
   -- K12_Benchmark
   --
   -- Generic procedure to run a benchmark for a KangarooTwelve 
   ----------------------------------------------------------------------------
   generic
      Name : String;
      with package K12 is new Keccak.Generic_KangarooTwelve(<>);
   procedure K12_Benchmark;
   
   procedure K12_Benchmark
   is
      Ctx    : K12.Context;
      
      Start_Time : Timing.Time;
      Cycles     : Cycles_Count;
      Min_Cycles : Cycles_Count := Cycles_Count'Last;
      
   begin
      Ada.Text_IO.Put(Name & " (Absorbing): ");
      
      -- Benchmark Absorbing
      for I in Positive range 1 .. Repeat loop
         Start_Measurement (Start_Time);
      
         K12.Init(Ctx);
         
         K12.Update(Ctx, Data_Chunk.all);
      
         K12.Finish (Ctx, "");
         
         Cycles := End_Measurement (Start_Time);
         
         if Cycles < Min_Cycles then
            Min_Cycles := Cycles;
         end if;
      end loop;
      
      Print_Cycles_Per_Byte (Data_Chunk.all'Length, Min_Cycles);
      
      Min_Cycles := Cycles_Count'Last;
      Ada.Text_IO.Put(Name & " (Squeezing): ");
      
      -- Benchmark squeezing
      for I in Positive range 1 .. Repeat loop
         Start_Measurement (Start_Time);
      
         K12.Extract(Ctx, Data_Chunk.all);
         
         Cycles := End_Measurement (Start_Time);
         
         if Cycles < Min_Cycles then
            Min_Cycles := Cycles;
         end if;
      end loop;
      
      Print_Cycles_Per_Byte (Data_Chunk.all'Length, Min_Cycles);
   end K12_Benchmark;
   
   ----------------------------------------------------------------------------
   -- Benchmark procedure instantiations.
   ----------------------------------------------------------------------------
   
   procedure Benchmark_SHA_224 is new Hash_Benchmark
      ("SHA3-224", SHA3.SHA3_224);
   procedure Benchmark_SHA_256 is new Hash_Benchmark
      ("SHA3-256", SHA3.SHA3_256);
   procedure Benchmark_SHA_384 is new Hash_Benchmark
      ("SHA3-384", SHA3.SHA3_384);
   procedure Benchmark_SHA_512 is new Hash_Benchmark
      ("SHA3-512", SHA3.SHA3_512);
   
   procedure Benchmark_Keccak_224 is new Hash_Benchmark
      ("Keccak-224", SHA3.Keccak_224);
   procedure Benchmark_Keccak_256 is new Hash_Benchmark
      ("Keccak-256", SHA3.Keccak_256);
   procedure Benchmark_Keccak_384 is new Hash_Benchmark
      ("Keccak-384", SHA3.Keccak_384);
   procedure Benchmark_Keccak_512 is new Hash_Benchmark
      ("Keccak-512", SHA3.Keccak_512);
   
   procedure Benchmark_SHAKE128 is new XOF_Benchmark
      ("SHAKE128", SHAKE.SHAKE128);
   procedure Benchmark_SHAKE256 is new XOF_Benchmark
      ("SHAKE256", SHAKE.SHAKE256);
   
   procedure Benchmark_RawSHAKE128 is new XOF_Benchmark
      ("RawSHAKE128", RawSHAKE.RawSHAKE128);
   procedure Benchmark_RawSHAKE256 is new XOF_Benchmark
      ("RawSHAKE256", RawSHAKE.RawSHAKE256);
   
   procedure Benchmark_Duplex_r1152c448 is new Duplex_Benchmark
      ("Duplex r1152c448", 448, Keccak.Keccak_1600.Duplex);
   procedure Benchmark_Duplex_r1088c512 is new Duplex_Benchmark
      ("Duplex r1088c512", 512, Keccak.Keccak_1600.Duplex);
   procedure Benchmark_Duplex_r832c768 is new Duplex_Benchmark
      ("Duplex r832c768", 768, Keccak.Keccak_1600.Duplex);
   procedure Benchmark_Duplex_r576c1024 is new Duplex_Benchmark
     ("Duplex r576c1024", 1024, Keccak.Keccak_1600.Duplex);
   
   procedure Benchmark_KeccakF_25 is new KeccakF_Benchmark
     ("Keccak-p[25,12]", 
      Keccak.Keccak_25.KeccakF_25.State, 
      Keccak.Keccak_25.KeccakF_25.Init, 
      Keccak.Keccak_25.Permute);
   procedure Benchmark_KeccakF_50 is new KeccakF_Benchmark
     ("Keccak-p[50,14]", 
      Keccak.Keccak_50.KeccakF_50.State, 
      Keccak.Keccak_50.KeccakF_50.Init, 
      Keccak.Keccak_50.Permute);
   procedure Benchmark_KeccakF_100 is new KeccakF_Benchmark
     ("Keccak-p[100,16]", 
      Keccak.Keccak_100.KeccakF_100.State, 
      Keccak.Keccak_100.KeccakF_100.Init, 
      Keccak.Keccak_100.Permute);
   procedure Benchmark_KeccakF_200 is new KeccakF_Benchmark
     ("Keccak-p[200,18]", 
      Keccak.Keccak_200.KeccakF_200.State, 
      Keccak.Keccak_200.KeccakF_200.Init,  
      Keccak.Keccak_200.Permute);
   procedure Benchmark_KeccakF_400 is new KeccakF_Benchmark
     ("Keccak-p[400,20]", 
      Keccak.Keccak_400.KeccakF_400.State, 
      Keccak.Keccak_400.KeccakF_400.Init, 
      Keccak.Keccak_400.Permute);
   procedure Benchmark_KeccakF_800 is new KeccakF_Benchmark
     ("Keccak-p[800,22]",
      Keccak.Keccak_800.KeccakF_800.State, 
      Keccak.Keccak_800.KeccakF_800.Init, 
      Keccak.Keccak_800.Permute);
   procedure Benchmark_KeccakF_1600 is new KeccakF_Benchmark
     ("Keccak-p[1600,24]", 
      Keccak.Keccak_1600.KeccakF_1600.State,
      Keccak.Keccak_1600.KeccakF_1600.Init, 
      Keccak.Keccak_1600.Permute_R24);
   procedure Benchmark_KeccakF_1600_P2_R12 is new KeccakF_Benchmark
     ("Keccak-p[1600,12]×2", 
      Keccak.Parallel_Keccak_1600.Parallel_State_P2,
      Keccak.Parallel_Keccak_1600.Init_P2, 
      Keccak.Parallel_Keccak_1600.Permute_All_P2_R12);
   procedure Benchmark_KeccakF_1600_P2_R24 is new KeccakF_Benchmark
     ("Keccak-p[1600,24]×2", 
      Keccak.Parallel_Keccak_1600.Parallel_State_P2,
      Keccak.Parallel_Keccak_1600.Init_P2, 
      Keccak.Parallel_Keccak_1600.Permute_All_P2_R24);
   
   procedure Benchmark_K12 is new K12_Benchmark
     ("KangarooTwelve",
      KangarooTwelve.K12);
      
   type Algorithm_Name is 
      (K12,
      SHA3_224,
      SHA3_256,
      SHA3_384,
      SHA3_512,
      Keccak_224,
      Keccak_256,
      Keccak_384,
      Keccak_512,
      SHAKE128,
      SHAKE256,
      RawSHAKE128,
      RawSHAKE256,
      Duplex_r1152c448,
      Duplex_r1088c512,
      Duplex_r832c768,
      Duplex_r576c1024,
      KeccakF_1600,
      KeccakF_1600_P2_R24,
      KeccakF_1600_P2_R12,
      KeccakF_800,
      KeccakF_400,
      KeccakF_200,
      KeccakF_100,
      KeccakF_50,
      KeccakF_25);
   
   Benchmarks_Enabled : array (Algorithm_Name) of Boolean := (others => False);

begin
   Data_Chunk.all := (others => 16#A7#);
   
   for I in 1 .. Ada.Command_Line.Argument_Count loop
      declare
         Arg : constant String := Ada.Command_Line.Argument (I);
      begin
         if Arg = "--all" then
            Benchmarks_Enabled := (others => True);
         elsif Arg = "--k12" then
            Benchmarks_Enabled (K12) := True;
         elsif Arg = "--sha3-224" then
            Benchmarks_Enabled (SHA3_224) := True;
         elsif Arg = "--sha3-256" then
            Benchmarks_Enabled (SHA3_256) := True;
         elsif Arg = "--sha3-384" then
            Benchmarks_Enabled (SHA3_384) := True;
         elsif Arg = "--sha3-512" then
            Benchmarks_Enabled (SHA3_512) := True;
         elsif Arg = "--keccak-224" then
            Benchmarks_Enabled (Keccak_224) := True;
         elsif Arg = "--keccak-256" then
            Benchmarks_Enabled (Keccak_256) := True;
         elsif Arg = "--keccak-384" then
            Benchmarks_Enabled (Keccak_384) := True;
         elsif Arg = "--keccak-512" then
            Benchmarks_Enabled (Keccak_512) := True;
         elsif Arg = "--shake128" then
            Benchmarks_Enabled (SHAKE128) := True;
         elsif Arg = "--shake256" then
            Benchmarks_Enabled (SHAKE256) := True;
         elsif Arg = "--rawshake128" then
            Benchmarks_Enabled (RawSHAKE128) := True;
         elsif Arg = "--rawshake256" then
            Benchmarks_Enabled (RawSHAKE256) := True;
         elsif Arg = "--duplex-r1152c448" then
            Benchmarks_Enabled (Duplex_r1152c448) := True;
         elsif Arg = "--duplex-r1088c512" then
            Benchmarks_Enabled (Duplex_r1088c512) := True;
         elsif Arg = "--duplex-r832c768" then
            Benchmarks_Enabled (Duplex_r832c768) := True;
         elsif Arg = "--duplex-r576c1024" then
            Benchmarks_Enabled (Duplex_r576c1024) := True;
         elsif Arg = "--keccak-f[1600,24]" then
            Benchmarks_Enabled (KeccakF_1600) := True;
         elsif Arg = "--keccak-f[1600,24]x2" then
            Benchmarks_Enabled (KeccakF_1600_P2_R24) := True;
         elsif Arg = "--keccak-f[1600,12]x2" then
            Benchmarks_Enabled (KeccakF_1600_P2_R12) := True;
         elsif Arg = "--keccak-f[800,22]" then
            Benchmarks_Enabled (KeccakF_800) := True;
         elsif Arg = "--keccak-f[400,20]" then
            Benchmarks_Enabled (KeccakF_400) := True;
         elsif Arg = "--keccak-f[200,18]" then
            Benchmarks_Enabled (KeccakF_200) := True;
         elsif Arg = "--keccak-f[100,16]" then
            Benchmarks_Enabled (KeccakF_100) := True;
         elsif Arg = "--keccak-f[50,14]" then
            Benchmarks_Enabled (KeccakF_50) := True;
         elsif Arg = "--keccak-f[25,12]" then
            Benchmarks_Enabled (KeccakF_25) := True;
         else
            Ada.Text_IO.Put_Line ("Unrecognized argument: " & Arg);
            Ada.Command_Line.Set_Exit_Status (1);
            return;
         end if;
      end;
   end loop;

   if Benchmarks_Enabled (K12) then
      Benchmark_K12;
   end if;

   if Benchmarks_Enabled (SHA3_224) then
      Benchmark_SHA_224;
   end if;
   
   if Benchmarks_Enabled (SHA3_256) then
      Benchmark_SHA_256;
   end if;
   
   if Benchmarks_Enabled (SHA3_384) then
      Benchmark_SHA_384;
   end if;
   
   if Benchmarks_Enabled (SHA3_512) then
      Benchmark_SHA_512;
   end if;
   
   if Benchmarks_Enabled (Keccak_224) then
      Benchmark_Keccak_224;
   end if;
   
   if Benchmarks_Enabled (Keccak_256) then
      Benchmark_Keccak_256;
   end if;
   
   if Benchmarks_Enabled (Keccak_384) then
      Benchmark_Keccak_384;
   end if;
   
   if Benchmarks_Enabled (Keccak_512) then
      Benchmark_Keccak_512;
   end if;
   
   if Benchmarks_Enabled (SHAKE128) then
      Benchmark_SHAKE128;
   end if;
   
   if Benchmarks_Enabled (SHAKE256) then
      Benchmark_SHAKE256;
   end if;
   
   if Benchmarks_Enabled (RawSHAKE128) then
      Benchmark_RawSHAKE128;
   end if;
   
   if Benchmarks_Enabled (RawSHAKE256) then
      Benchmark_RawSHAKE256;
   end if;
   
   if Benchmarks_Enabled (Duplex_r1152c448) then
      Benchmark_Duplex_r1152c448;
   end if;
   
   if Benchmarks_Enabled (Duplex_r1088c512) then
      Benchmark_Duplex_r1088c512;
   end if;
   
   if Benchmarks_Enabled (Duplex_r832c768) then
      Benchmark_Duplex_r832c768;
   end if;
   
   if Benchmarks_Enabled (Duplex_r576c1024) then
      Benchmark_Duplex_r576c1024;
   end if;
   
   if Benchmarks_Enabled (KeccakF_1600) then
      Benchmark_KeccakF_1600;
   end if;
   
   if Benchmarks_Enabled (KeccakF_1600_P2_R24) then
      Benchmark_KeccakF_1600_P2_R24;
   end if;
   
   if Benchmarks_Enabled (KeccakF_1600_P2_R12) then
      Benchmark_KeccakF_1600_P2_R12;
   end if;
   
   if Benchmarks_Enabled (KeccakF_800) then
      Benchmark_KeccakF_800;
   end if;
   
   if Benchmarks_Enabled (KeccakF_400) then
      Benchmark_KeccakF_400;
   end if;
   
   if Benchmarks_Enabled (KeccakF_200) then
      Benchmark_KeccakF_200;
   end if;
   
   if Benchmarks_Enabled (KeccakF_100) then
      Benchmark_KeccakF_100;
   end if;
   
   if Benchmarks_Enabled (KeccakF_50) then
      Benchmark_KeccakF_50;
   end if;
   
   if Benchmarks_Enabled (KeccakF_25) then
      Benchmark_KeccakF_25;
   end if;
end Benchmark;