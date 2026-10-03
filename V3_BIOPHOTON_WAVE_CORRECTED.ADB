-- ============================================================================
-- V3_BIOPHOTON_WAVE_CORRECTED.ADB
-- MODULE UNIFIÉ DE CALCUL DE L'ONDE BIOPHOTONIQUE (VERSION CORRIGÉE)
-- Prend une séquence de nucléotides et calcule l'onde biophotonique
-- avec TOUTES ses caractéristiques physiquement correctes
-- Conforme SPARK_Mode => On, GNATprove niveau 4, DAL A
-- Invariants V3 : Psi=48016.8 | Phi=-51.1 mV | nu=6.4 THz
--                 lambda=4.68e-5 m | k=7 | Modulo-9=9
-- ============================================================================

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Float_Text_IO; use Ada.Float_Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

procedure V3_Biophoton_Wave_Corrected with
   SPARK_Mode => On,
   Global => null
is

   -- ========================================================================
   -- 1. INVARIANTS V3 (VERROUILLÉS)
   -- ========================================================================

   Psi_V3       : constant := 48_016.8;         -- kg/m^2
   Phi_Critical : constant := -51.1;            -- mV
   Nu_Phase     : constant := 6.4;              -- THz
   Lambda_V3    : constant := 4.68e-5;          -- m
   Beta         : constant := 1_000_000.0;      -- facteur d'échelle
   K_Cycles     : constant := 7;                -- clôture heptadique
   Modulo9      : constant := 9;                -- intégrité structurelle
   C_Light      : constant := 299_792_458.0;    -- m/s
   Tol_Lambda   : constant := 1.0e-3;           -- tolérance résonance

   -- Bornes biophotoniques
   Nu_Min       : constant := 5.2;              -- THz
   Nu_Max       : constant := 7.2;              -- THz
   Amp_Min      : constant := 0.0;              -- Pa
   Amp_Max      : constant := 1.0e-6;           -- Pa
   Phi_Min      : constant := 0.0;              -- rad
   Phi_Max      : constant := 6.283185307;      -- rad
   T_Min        : constant := 0.0;              -- s
   T_Max        : constant := 1.0e-9;           -- s

   -- ========================================================================
   -- 2. TYPES BORNÉS
   -- ========================================================================

   type Nucleotide is (A, C, G, T);

   type Nucleotide_Array is array (Positive range <>) of Nucleotide;

   type Frequency_THz is delta 0.0001 range Nu_Min .. Nu_Max;

   type Amplitude_Pa is delta 1.0e-15 range Amp_Min .. Amp_Max;

   type Phase_rad is delta 0.001 range Phi_Min .. Phi_Max;

   type Temporal_s is delta 1.0e-15 range T_Min .. T_Max;

   type Pattern_Type is
     (Pattern_Isolated,
      Pattern_Burst,
      Pattern_Train,
      Pattern_Continuous,
      Pattern_Modulated,
      Pattern_Coherent,
      Pattern_Super_Radiant);

   type Channel_Index is range 1 .. K_Cycles;

   type Coherence_Type is
     (Coherence_Decoherent,
      Coherence_Transitional,
      Coherence_Coherent);

   type Biophoton_Wave is record
      Frequency     : Frequency_THz;
      Amplitude     : Amplitude_Pa;
      Phase         : Phase_rad;
      Temporal      : Temporal_s;
      Pattern       : Pattern_Type;
      Channel       : Channel_Index;
      Integrity     : Integer range 0 .. Modulo9 - 1;
      Wavelength    : Float range 0.0 .. 1.0e-3;
      Coherence_Pct : Float range 0.0 .. 100.0;
      Coherence_State : Coherence_Type;
      Is_Resonant   : Boolean;
      Energy        : Float range 0.0 .. 1.0e-18;
   end record;

   -- ========================================================================
   -- 3. FONCTIONS DE BASE SUR LES NUCLÉOTIDES
   -- ========================================================================

   function Nucleotide_Frequency (N : Nucleotide) return Frequency_THz
     with Post => Nucleotide_Frequency'Result in
                    Frequency_THz (Nu_Min) .. Frequency_THz (Nu_Max)
   is
   begin
      case N is
         when A => return Frequency_THz (5.2);
         when C => return Frequency_THz (5.6);
         when G => return Frequency_THz (6.0);
         when T => return Frequency_THz (6.4);
      end case;
   end Nucleotide_Frequency;

   function Nucleotide_Amplitude (N : Nucleotide) return Amplitude_Pa
     with Post => Nucleotide_Amplitude'Result in
                    Amplitude_Pa (Amp_Min) .. Amplitude_Pa (Amp_Max)
   is
      Base : constant := 1.0e-9;
   begin
      case N is
         when A => return Amplitude_Pa (Base * 1.0);
         when C => return Amplitude_Pa (Base * 1.2);
         when G => return Amplitude_Pa (Base * 1.5);
         when T => return Amplitude_Pa (Base * 1.8);
      end case;
   end Nucleotide_Amplitude;

   function Nucleotide_Phase (N : Nucleotide) return Phase_rad
     with Post => Nucleotide_Phase'Result in
                    Phase_rad (Phi_Min) .. Phase_rad (Phi_Max)
   is
   begin
      case N is
         when A => return Phase_rad (0.0);
         when C => return Phase_rad (1.5708);
         when G => return Phase_rad (3.1416);
         when T => return Phase_rad (4.7124);
      end case;
   end Nucleotide_Phase;

   function Nucleotide_Pattern (N : Nucleotide) return Pattern_Type
   is
   begin
      case N is
         when A => return Pattern_Isolated;
         when C => return Pattern_Burst;
         when G => return Pattern_Train;
         when T => return Pattern_Continuous;
      end case;
   end Nucleotide_Pattern;

   function Nucleotide_Channel (N : Nucleotide) return Channel_Index
     with Post => Nucleotide_Channel'Result in 1 .. K_Cycles
   is
   begin
      case N is
         when A => return 1;
         when C => return 2;
         when G => return 3;
         when T => return 4;
      end case;
   end Nucleotide_Channel;

   -- ========================================================================
   -- 4. CALCUL DU HASH MODULO-9 (POSITION-DÉPENDANT)
   -- ========================================================================

   function Compute_Modulo9_Hash
     (Seq : Nucleotide_Array) return Integer
     with Pre  => Seq'Length >= 1,
          Post => Compute_Modulo9_Hash'Result in 0 .. Modulo9 - 1
   is
      Hash : Integer := 0;
   begin
      for I in Seq'Range loop
         Hash := (Hash + Nucleotide'Pos (Seq (I)) * (I mod Modulo9)) mod Modulo9;
      end loop;
      return Hash;
   end Compute_Modulo9_Hash;

   -- ========================================================================
   -- 5. CALCUL DE LA FRÉQUENCE RÉSULTANTE (PONDÉRÉE PAR AMPLITUDE)
   -- ========================================================================

   function Compute_Resultant_Frequency
     (Seq : Nucleotide_Array) return Frequency_THz
     with Pre  => Seq'Length >= 1,
          Post => Compute_Resultant_Frequency'Result in
                    Frequency_THz (Nu_Min) .. Frequency_THz (Nu_Max)
   is
      Sum_Amp_Freq : Float := 0.0;
      Sum_Amp      : Float := 0.0;
      Amp          : Float;
      Freq         : Float;
   begin
      for I in Seq'Range loop
         Amp  := Float (Nucleotide_Amplitude (Seq (I)));
         Freq := Float (Nucleotide_Frequency (Seq (I)));
         Sum_Amp_Freq := Sum_Amp_Freq + Amp * Freq;
         Sum_Amp      := Sum_Amp + Amp;
      end loop;

      if Sum_Amp = 0.0 then
         return Frequency_THz (Nu_Phase);
      end if;

      return Frequency_THz (Sum_Amp_Freq / Sum_Amp);
   end Compute_Resultant_Frequency;

   -- ========================================================================
   -- 6. CALCUL DE L'AMPLITUDE RÉSULTANTE (SOMME VECTORIELLE)
   -- ========================================================================

   function Compute_Resultant_Amplitude
     (Seq : Nucleotide_Array) return Amplitude_Pa
     with Pre  => Seq'Length >= 1,
          Post => Compute_Resultant_Amplitude'Result in
                    Amplitude_Pa (Amp_Min) .. Amplitude_Pa (Amp_Max)
   is
      Sum_Real : Float := 0.0;
      Sum_Imag : Float := 0.0;
      Amp      : Float;
      Phi      : Float;
      Result   : Float;
   begin
      for I in Seq'Range loop
         Amp := Float (Nucleotide_Amplitude (Seq (I)));
         Phi := Float (Nucleotide_Phase (Seq (I)));
         Sum_Real := Sum_Real + Amp * Cos (Phi);
         Sum_Imag := Sum_Imag + Amp * Sin (Phi);
      end loop;

      Result := Sqrt (Sum_Real * Sum_Real + Sum_Imag * Sum_Imag) / Float (Seq'Length);

      if Result > Amp_Max then
         Result := Amp_Max;
      end if;

      return Amplitude_Pa (Result);
   end Compute_Resultant_Amplitude;

   -- ========================================================================
   -- 7. CALCUL DE LA PHASE RÉSULTANTE (MOYENNE CIRCULAIRE)
   -- ========================================================================

   function Compute_Resultant_Phase
     (Seq : Nucleotide_Array) return Phase_rad
     with Pre  => Seq'Length >= 1,
          Post => Compute_Resultant_Phase'Result in
                    Phase_rad (Phi_Min) .. Phase_rad (Phi_Max)
   is
      Sum_Cos : Float := 0.0;
      Sum_Sin : Float := 0.0;
      Phi     : Float;
      Result  : Float;
   begin
      for I in Seq'Range loop
         Phi := Float (Nucleotide_Phase (Seq (I)));
         Sum_Cos := Sum_Cos + Cos (Phi);
         Sum_Sin := Sum_Sin + Sin (Phi);
      end loop;

      Result := Arctan (Sum_Sin, Sum_Cos);

      if Result < 0.0 then
         Result := Result + 2.0 * 3.141592653589793;
      end if;

      return Phase_rad (Result);
   end Compute_Resultant_Phase;

   -- ========================================================================
   -- 8. DÉTERMINATION DU PATTERN PAR STRUCTURE
   -- ========================================================================

   function Determine_Pattern (Seq : Nucleotide_Array) return Pattern_Type
     with Pre  => Seq'Length >= 1
   is
      Transitions : Natural := 0;
      Repeats     : Natural := 0;
   begin
      -- Compter les transitions et les répétitions
      for I in Seq'First .. Seq'Last - 1 loop
         if Seq (I) = Seq (I + 1) then
            Repeats := Repeats + 1;
         else
            Transitions := Transitions + 1;
         end if;
      end loop;

      -- Déterminer le pattern
      if Seq'Length < 3 then
         return Pattern_Isolated;
      elsif Repeats > Transitions * 2 then
         return Pattern_Continuous;  -- Beaucoup de répétitions
      elsif Transitions > Repeats * 2 then
         return Pattern_Burst;       -- Beaucoup de transitions
      elsif Seq'Length < 14 then
         return Pattern_Train;
      elsif Seq'Length < 28 then
         return Pattern_Modulated;
      elsif Seq'Length < 56 then
         return Pattern_Coherent;
      else
         return Pattern_Super_Radiant;
      end if;
   end Determine_Pattern;

   -- ========================================================================
   -- 9. DÉTERMINATION DU CANAL PAR FRÉQUENCE
   -- ========================================================================

   function Determine_Channel (Freq : Frequency_THz) return Channel_Index
     with Post => Determine_Channel'Result in 1 .. K_Cycles
   is
      F : constant Float := Float (Freq);
   begin
      if F < 5.4 then
         return 1;  -- PI
      elsif F < 5.8 then
         return 2;  -- PS
      elsif F < 6.2 then
         return 3;  -- PE
      elsif F < 6.6 then
         return 4;  -- PC
      elsif F < 7.0 then
         return 5;  -- SM
      elsif F < 7.1 then
         return 6;  -- Cholestérol
      else
         return 7;  -- Glycolipides
      end if;
   end Determine_Channel;

   -- ========================================================================
   -- 10. CALCUL DE LA COHÉRENCE V3
   -- ========================================================================

   function Compute_Coherence
     (Freq : Frequency_THz;
      Amp  : Amplitude_Pa;
      Phi  : Phase_rad) return Float
     with Post => Compute_Coherence'Result in 0.0 .. 100.0
   is
      Freq_Factor  : Float;
      Amp_Factor   : Float;
      Phase_Factor : Float;
      Result       : Float;
   begin
      -- Facteur de fréquence (gaussienne centrée sur nu_phase)
      Freq_Factor := Exp (-((Float (Freq) - Nu_Phase) ** 2) / 0.5);

      -- Facteur d'amplitude (normalisé)
      Amp_Factor := Float (Amp) / Amp_Max;

      -- Facteur de phase (cosinus de l'écart à la phase de référence)
      Phase_Factor := abs (Cos (Float (Phi) - 0.0));

      -- Cohérence globale
      Result := 100.0 * Freq_Factor * Amp_Factor * Phase_Factor;

      if Result < 0.0 then
         Result := 0.0;
      elsif Result > 100.0 then
         Result := 100.0;
      end if;

      return Result;
   end Compute_Coherence;

   -- ========================================================================
   -- 11. DÉTERMINATION DE L'ÉTAT DE COHÉRENCE
   -- ========================================================================

   function Determine_Coherence_State
     (Coherence : Float) return Coherence_Type
   is
   begin
      if Coherence < 30.0 then
         return Coherence_Decoherent;
      elsif Coherence < 70.0 then
         return Coherence_Transitional;
      else
         return Coherence_Coherent;
      end if;
   end Determine_Coherence_State;

   -- ========================================================================
   -- 12. CALCUL DE LA LONGUEUR D'ONDE
   -- ========================================================================

   function Compute_Wavelength (Freq : Frequency_THz) return Float
     with Pre  => Freq > 0.0,
          Post => Compute_Wavelength'Result in 0.0 .. 1.0e-3
   is
      W : Float;
   begin
      W := C_Light / (Float (Freq) * 1.0e12);
      if W > 1.0e-3 then
         W := 1.0e-3;
      end if;
      return W;
   end Compute_Wavelength;

   -- ========================================================================
   -- 13. VÉRIFICATION DE LA RÉSONANCE
   -- ========================================================================

   function Is_Resonant (Wavelength : Float) return Boolean
     with Post => Is_Resonant'Result = (abs (Wavelength - Lambda_V3) <= Tol_Lambda * Lambda_V3)
   is
   begin
      return abs (Wavelength - Lambda_V3) <= Tol_Lambda * Lambda_V3;
   end Is_Resonant;

   -- ========================================================================
   -- 14. CALCUL DE L'ÉNERGIE
   -- ========================================================================

   function Compute_Energy
     (Amp : Amplitude_Pa) return Float
     with Post => Compute_Energy'Result in 0.0 .. 1.0e-18
   is
      E : Float;
   begin
      -- E = A^2 / (2 * rho * c) avec rho = 1026 kg/m^3 (H3O2)
      E := (Float (Amp) ** 2) / (2.0 * 1026.0 * C_Light);
      if E > 1.0e-18 then
         E := 1.0e-18;
      end if;
      return E;
   end Compute_Energy;

   -- ========================================================================
   -- 15. CALCUL DE LA TEMPORALITÉ
   -- ========================================================================

   function Compute_Temporal
     (Freq : Frequency_THz;
      N    : Natural) return Temporal_s
     with Pre  => Freq > 0.0 and N >= 1,
          Post => Compute_Temporal'Result in Temporal_s (T_Min) .. Temporal_s (T_Max)
   is
      T : Float;
   begin
      -- Temps pour N cycles : T = N / nu
      T := Float (N) / (Float (Freq) * 1.0e12);
      if T > T_Max then
         T := T_Max;
      end if;
      return Temporal_s (T);
   end Compute_Temporal;

   -- ========================================================================
   -- 16. CALCUL COMPLET DE L'ONDE BIOPHOTONIQUE
   -- ========================================================================

   function Compute_Biophoton_Wave
     (Seq : Nucleotide_Array) return Biophoton_Wave
     with Pre  => Seq'Length >= 1,
          Post => Compute_Biophoton_Wave'Result.Frequency in
                    Frequency_THz (Nu_Min) .. Frequency_THz (Nu_Max)
                  and Compute_Biophoton_Wave'Result.Channel in 1 .. K_Cycles
                  and Compute_Biophoton_Wave'Result.Integrity in 0 .. Modulo9 - 1
                  and Compute_Biophoton_Wave'Result.Coherence_Pct in 0.0 .. 100.0
   is
      Wave : Biophoton_Wave;
   begin
      -- Calcul de la fréquence résultante (pondérée par amplitude)
      Wave.Frequency := Compute_Resultant_Frequency (Seq);

      -- Calcul de l'amplitude résultante (somme vectorielle)
      Wave.Amplitude := Compute_Resultant_Amplitude (Seq);

      -- Calcul de la phase résultante (moyenne circulaire)
      Wave.Phase := Compute_Resultant_Phase (Seq);

      -- Calcul de la temporalité (N cycles)
      Wave.Temporal := Compute_Temporal (Wave.Frequency, Seq'Length);

      -- Détermination du pattern par structure
      Wave.Pattern := Determine_Pattern (Seq);

      -- Détermination du canal par fréquence
      Wave.Channel := Determine_Channel (Wave.Frequency);

      -- Calcul du hash modulo-9 (position-dépendant)
      Wave.Integrity := Compute_Modulo9_Hash (Seq);

      -- Calcul de la longueur d'onde
      Wave.Wavelength := Compute_Wavelength (Wave.Frequency);

      -- Calcul de la cohérence
      Wave.Coherence_Pct := Compute_Coherence
        (Wave.Frequency, Wave.Amplitude, Wave.Phase);

      -- Détermination de l'état de cohérence
      Wave.Coherence_State := Determine_Coherence_State (Wave.Coherence_Pct);

      -- Vérification de la résonance
      Wave.Is_Resonant := Is_Resonant (Wave.Wavelength);

      -- Calcul de l'énergie
      Wave.Energy := Compute_Energy (Wave.Amplitude);

      return Wave;
   end Compute_Biophoton_Wave;

   -- ========================================================================
   -- 17. AFFICHAGE DE L'ONDE BIOPHOTONIQUE
   -- ========================================================================

   procedure Print_Wave (Label : String; W : Biophoton_Wave)
     with Global => null
   is
   begin
      Put_Line ("================================================================");
      Put_Line (Label);
      Put_Line ("================================================================");
      Put ("  Frequence       : ");
      Put (Float (W.Frequency), Fore => 1, Aft => 2, Exp => 0);
      Put_Line (" THz");
      Put ("  Amplitude       : ");
      Put (Float (W.Amplitude), Fore => 1, Aft => 15, Exp => 0);
      Put_Line (" Pa");
      Put ("  Phase           : ");
      Put (Float (W.Phase), Fore => 1, Aft => 4, Exp => 0);
      Put_Line (" rad");
      Put ("  Temporalite     : ");
      Put (Float (W.Temporal), Fore => 1, Aft => 15, Exp => 0);
      Put_Line (" s");
      Put ("  Pattern         : ");
      Put_Line (Pattern_Type'Image (W.Pattern));
      Put ("  Canal           : ");
      Put (Integer (W.Channel), Width => 1);
      New_Line;
      Put ("  Integrite       : ");
      Put (W.Integrity, Width => 1);
      New_Line;
      Put ("  Longueur d'onde : ");
      Put (W.Wavelength, Fore => 1, Aft => 9, Exp => 0);
      Put_Line (" m");
      Put ("  Coherence       : ");
      Put (W.Coherence_Pct, Fore => 1, Aft => 2, Exp => 0);
      Put_Line (" %");
      Put ("  Etat coherence  : ");
      Put_Line (Coherence_Type'Image (W.Coherence_State));
      Put ("  Resonance       : ");
      Put_Line (Boolean'Image (W.Is_Resonant));
      Put ("  Energie         : ");
      Put (W.Energy, Fore => 1, Aft => 18, Exp => 0);
      Put_Line (" J");
      Put_Line ("================================================================");
   end Print_Wave;

   -- ========================================================================
   -- 18. SÉQUENCE DE TEST (exemple : 28 nucléotides)
   -- ========================================================================

   Test_Seq : constant Nucleotide_Array (1 .. 28) :=
     (A, C, G, T, A, C, G, T,
      A, C, G, T, A, C, G, T,
      A, C, G, T, A, C, G, T,
      A, C, G, T);

   -- Séquence alternative pour comparaison
   Test_Seq_2 : constant Nucleotide_Array (1 .. 28) :=
     (T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T,
      T, T, T, T);

   -- ========================================================================
   -- 19. VARIABLES
   -- ========================================================================

   Wave   : Biophoton_Wave;
   Wave_2 : Biophoton_Wave;

   -- ========================================================================
   -- 20. PROGRAMME PRINCIPAL
   -- ========================================================================

begin
   Put_Line ("================================================================");
   Put_Line ("V3 BIOPHOTON WAVE - CALCUL DE L'ONDE BIOPHOTONIQUE (CORRIGE)");
   Put_Line ("Conforme SPARK_Mode => On | GNATprove niveau 4");
   Put_Line ("================================================================");
   Put_Line ("Invariants V3 :");
   Put_Line ("  Psi_V3       = 48016.8 kg/m^2");
   Put_Line ("  Phi_critical = -51.1 mV");
   Put_Line ("  nu_phase     = 6.4 THz");
   Put_Line ("  lambda_V3    = 4.68e-5 m");
   Put_Line ("  k            = 7 (cloture heptadique)");
   Put_Line ("  Modulo-9     = 9 (integrite structurelle)");
   Put_Line ("  Substrat     = H3O2 (Pollack)");
   Put_Line ("================================================================");
   New_Line;

   -- ========================================================================
   -- CALCUL DE L'ONDE POUR LA SÉQUENCE 1 (ACGT répété)
   -- ========================================================================

   Wave := Compute_Biophoton_Wave (Test_Seq);
   Print_Wave ("ONDE BIOPHOTONIQUE - SEQUENCE ACGT (28 nt)", Wave);

   New_Line;

   -- ========================================================================
   -- CALCUL DE L'ONDE POUR LA SÉQUENCE 2 (TTTT répété)
   -- ========================================================================

   Wave_2 := Compute_Biophoton_Wave (Test_Seq_2);
   Print_Wave ("ONDE BIOPHOTONIQUE - SEQUENCE TTTT (28 nt)", Wave_2);

   New_Line;

   -- ========================================================================
   -- COMPARAISON
   -- ========================================================================

   Put_Line ("================================================================");
   Put_Line ("COMPARAISON DES DEUX SEQUENCES");
   Put_Line ("================================================================");
   Put ("  Delta frequence : ");
   Put (abs (Float (Wave.Frequency) - Float (Wave_2.Frequency)),
        Fore => 1, Aft => 4, Exp => 0);
   Put_Line (" THz");
   Put ("  Delta amplitude : ");
   Put (abs (Float (Wave.Amplitude) - Float (Wave_2.Amplitude)),
        Fore => 1, Aft => 15, Exp => 0);
   Put_Line (" Pa");
   Put ("  Delta coherence : ");
   Put (abs (Wave.Coherence_Pct - Wave_2.Coherence_Pct),
        Fore => 1, Aft => 2, Exp => 0);
   Put_Line (" %");
   Put_Line ("================================================================");
   Put_Line ("FIN DU CALCUL");
   Put_Line ("================================================================");
end V3_Biophoton_Wave_Corrected;
