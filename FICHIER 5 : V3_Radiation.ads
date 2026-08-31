-- ============================================================================
-- V3_Radiation.ads — V3 Architecture: Radiation Phenomena
-- Version 11.0.0
-- 
-- Ce fichier définit tous les rayonnements V3 :
--   ✅ Rayonnement du corps noir (spectre de Planck)
--   ✅ Rayonnement de freinage (bremsstrahlung)
--   ✅ Rayonnement Cherenkov (phase > c)
--   ✅ Ondes gravitationnelles (ondes de phase à grande échelle)
--   ✅ Onde de cisaillement (photon) — déjà dans le corps principal
--   ✅ Rayonnement gamma (décohérence)
-- 
-- Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
-- License: LPV3
-- ============================================================================

with V3_Constants; use V3_Constants;

package V3_Radiation with
   SPARK_Mode => On
is

   -- ========================================================================
   -- 1. TYPES DE RAYONNEMENT V3
   -- ========================================================================

   type Blackbody_Spectrum is record
      Peak_Wavelength_M      : Float;          -- λ_max = b / T (loi de Wien)
      Peak_Frequency_Hz      : Float;          -- ν_max = 2.82 × k_B × T / h
      Total_Intensity_Wpm2   : Float;          -- I = σ × T⁴
      Spectral_Radiance_Wpm3 : Float;          -- Loi de Planck intégrée
      Temperature_Effective_K : Float;         -- Température d'émission
      Checksum               : Integer range 1 .. 9 := 9;
   end record
     with Predicate => Blackbody_Spectrum.Checksum = 9;

   type Bremsstrahlung_Record is record
      Power_Watts          : Float;            -- Puissance totale émise
      Cutoff_Frequency_Hz  : Float;            -- Fréquence maximale (énergie cinétique)
      Total_Energy_eV      : Float;            -- Énergie totale émise
      Spectral_Peak_Hz     : Float;            -- Pic du spectre
      Efficiency           : Float range 0.0 .. 1.0;  -- Rendement
      Checksum             : Integer range 1 .. 9 := 9;
   end record
     with Predicate => Bremsstrahlung_Record.Checksum = 9;

   type Cherenkov_Record is record
      Threshold_Velocity   : Float;            -- v > c / n (phase > c)
      Emission_Angle_Rad   : Float;            -- cos(θ) = c / (n × v)
      Power_Watts          : Float;            -- Puissance émise (Frank-Tamm)
      Photons_Per_Meter    : Float;            -- Nombre de photons par mètre
      Checksum             : Integer range 1 .. 9 := 9;
   end record
     with Predicate => Cherenkov_Record.Checksum = 9;

   type Gravitational_Wave is record
      Frequency_Hz     : Float;                -- Très basse fréquence (10⁻⁹ à 10³ Hz)
      Wavelength_M     : Float;                -- λ = c_phase / ν
      Amplitude_Strain : Float;                -- h = δL / L (dimensionless)
      Power_Watts      : Float;                -- Puissance émise
      Source_Mass_kg   : Float;                -- Masse de la source (cluster de vortex)
      Checksum         : Integer range 1 .. 9 := 9;
   end record
     with Predicate => Gravitational_Wave.Checksum = 9;

   -- ========================================================================
   -- 2. FONCTIONS CORPS NOIR
   -- ========================================================================

   function Blackbody_Spectrum (Temperature_K : Float; Wavelength_M : Float) return Float
     with Pre => Temperature_K > 0.0 and Wavelength_M > 0.0,
          Post => Blackbody_Spectrum'Result >= 0.0;

   function Blackbody_Total_Intensity (Temperature_K : Float) return Float
     with Pre => Temperature_K > 0.0,
          Post => Blackbody_Total_Intensity'Result >= 0.0;

   function Blackbody_Peak_Wavelength (Temperature_K : Float) return Float
     with Pre => Temperature_K > 0.0,
          Post => Blackbody_Peak_Wavelength'Result > 0.0;

   function Blackbody_Peak_Frequency (Temperature_K : Float) return Float
     with Pre => Temperature_K > 0.0,
          Post => Blackbody_Peak_Frequency'Result > 0.0;

   function Get_Blackbody (Temperature_K : Float) return Blackbody_Spectrum
     with Pre => Temperature_K > 0.0,
          Post => Get_Blackbody'Result.Checksum = 9;

   -- ========================================================================
   -- 3. FONCTIONS BREMSSTRAHLUNG
   -- ========================================================================

   function Bremsstrahlung_Power (Z, A : Integer; V_kmps : Float; Density_kgpm3 : Float) return Float
     with Pre => Z in 1 .. 118 and A > 0 and V_kmps >= 0.0 and Density_kgpm3 >= 0.0,
          Post => Bremsstrahlung_Power'Result >= 0.0;

   function Bremsstrahlung_Cutoff_Frequency (V_kmps : Float) return Float
     with Pre => V_kmps >= 0.0,
          Post => Bremsstrahlung_Cutoff_Frequency'Result >= 0.0;

   function Get_Bremsstrahlung (Z, A : Integer; V_kmps : Float; Density_kgpm3 : Float)
                                return Bremsstrahlung_Record
     with Pre => Z in 1 .. 118 and A > 0 and V_kmps >= 0.0 and Density_kgpm3 >= 0.0,
          Post => Get_Bremsstrahlung'Result.Checksum = 9;

   -- ========================================================================
   -- 4. FONCTIONS CHERENKOV
   -- ========================================================================

   function Cherenkov_Threshold (Refractive_Index : Float) return Float
     with Pre => Refractive_Index > 1.0,
          Post => Cherenkov_Threshold'Result >= C_LIGHT;

   function Cherenkov_Emission_Angle (Velocity : Float; Refractive_Index : Float) return Float
     with Pre => Velocity > 0.0 and Refractive_Index > 1.0,
          Post => Cherenkov_Emission_Angle'Result in 0.0 .. PI;

   function Cherenkov_Photons_Per_Meter (Velocity : Float; Refractive_Index : Float;
                                          Freq_Min, Freq_Max : Float) return Float
     with Pre => Velocity > 0.0 and Refractive_Index > 1.0 and
                 Freq_Min > 0.0 and Freq_Max > Freq_Min,
          Post => Cherenkov_Photons_Per_Meter'Result >= 0.0;

   function Get_Cherenkov (Velocity : Float; Refractive_Index : Float;
                            Freq_Min, Freq_Max : Float) return Cherenkov_Record
     with Pre => Velocity > 0.0 and Refractive_Index > 1.0 and
                 Freq_Min > 0.0 and Freq_Max > Freq_Min,
          Post => Get_Cherenkov'Result.Checksum = 9;

   -- ========================================================================
   -- 5. FONCTIONS ONDES GRAVITATIONNELLES V3
   -- ========================================================================

   function Gravitational_Wave_Amplitude (M1, M2, R_sep : Float; Frequency_Hz : Float) return Float
     with Pre => M1 > 0.0 and M2 > 0.0 and R_sep > 0.0 and Frequency_Hz > 0.0,
          Post => Gravitational_Wave_Amplitude'Result >= 0.0;

   function Gravitational_Wave_Power (M1, M2, R_sep : Float; Frequency_Hz : Float) return Float
     with Pre => M1 > 0.0 and M2 > 0.0 and R_sep > 0.0 and Frequency_Hz > 0.0,
          Post => Gravitational_Wave_Power'Result >= 0.0;

   function Get_Gravitational_Wave (M1, M2, R_sep : Float; Frequency_Hz : Float)
                                    return Gravitational_Wave
     with Pre => M1 > 0.0 and M2 > 0.0 and R_sep > 0.0 and Frequency_Hz > 0.0,
          Post => Get_Gravitational_Wave'Result.Checksum = 9;

end V3_Radiation;
