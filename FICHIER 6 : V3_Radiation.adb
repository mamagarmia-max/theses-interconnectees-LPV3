-- ============================================================================
-- V3_Radiation.adb — Implementation V3_Radiation
-- Version 11.0.0
-- ============================================================================

package body V3_Radiation with
   SPARK_Mode => On
is

   -- ========================================================================
   -- 2. FONCTIONS CORPS NOIR
   -- ========================================================================

   function Blackbody_Spectrum (Temperature_K : Float; Wavelength_M : Float) return Float is
      -- Loi de Planck : B(λ,T) = (2hc²/λ⁵) × 1/(exp(hc/λk_BT) - 1)
      hc  : constant Float := H_PLANK * C_LIGHT;
      hc_over_lambda : Float := hc / (Wavelength_M * K_B * Temperature_K);
      Numerator : Float := 2.0 * H_PLANK * C_LIGHT * C_LIGHT / (Wavelength_M ** 5.0);
   begin
      if hc_over_lambda > 100.0 then
         return Numerator * exp (-hc_over_lambda);  -- Approximation de Wien
      elsif hc_over_lambda < 0.01 then
         -- Approximation de Rayleigh-Jeans (pour basse fréquence)
         return 2.0 * K_B * Temperature_K / (Wavelength_M ** 4.0);
      else
         return Numerator / (exp (hc_over_lambda) - 1.0);
      end if;
   end Blackbody_Spectrum;

   function Blackbody_Total_Intensity (Temperature_K : Float) return Float is
   begin
      -- Loi de Stefan-Boltzmann : I = σ × T⁴
      return SIGMA_SB * Temperature_K ** 4.0;
   end Blackbody_Total_Intensity;

   function Blackbody_Peak_Wavelength (Temperature_K : Float) return Float is
   begin
      -- Loi de Wien : λ_max = b / T
      return WIEN_CONSTANT / Temperature_K;
   end Blackbody_Peak_Wavelength;

   function Blackbody_Peak_Frequency (Temperature_K : Float) return Float is
      -- ν_max = 2.821439 × k_B × T / h
      Peak_Constant : constant Float := 2.821439;  -- Solution de (3-x)*exp(x) = 3
   begin
      return Peak_Constant * K_B * Temperature_K / H_PLANK;
   end Blackbody_Peak_Frequency;

   function Get_Blackbody (Temperature_K : Float) return Blackbody_Spectrum is
      Lambda_Peak : Float := Blackbody_Peak_Wavelength (Temperature_K);
      Nu_Peak     : Float := Blackbody_Peak_Frequency (Temperature_K);
      Intensity   : Float := Blackbody_Total_Intensity (Temperature_K);
      Radiance    : Float := Blackbody_Spectrum (Temperature_K, Lambda_Peak);
   begin
      return Blackbody_Spectrum'
        (Peak_Wavelength_M      => Lambda_Peak,
         Peak_Frequency_Hz      => Nu_Peak,
         Total_Intensity_Wpm2   => Intensity,
         Spectral_Radiance_Wpm3 => Radiance,
         Temperature_Effective_K => Temperature_K,
         Checksum               => 9);
   end Get_Blackbody;

   -- ========================================================================
   -- 3. FONCTIONS BREMSSTRAHLUNG
   -- ========================================================================

   function Bremsstrahlung_Power (Z, A : Integer; V_kmps : Float; Density_kgpm3 : Float) return Float is
      -- P = 1.7e-38 × Z² × n_e × T_e^0.5 (approximation V3 adaptée)
      V_ms : Float := V_kmps * 1000.0;                     -- m/s
      n_e  : Float := Density_kgpm3 / (AMU * Float (A));   -- densité électronique
      T_K  : Float := (V_ms * V_ms) / (3.0 * K_B / M_E);   -- température équivalente
   begin
      -- Puissance bremsstrahlung : ∝ Z² × n_e × √T
      return 1.7e-38 * Float (Z * Z) * n_e * (T_K ** 0.5);
   end Bremsstrahlung_Power;

   function Bremsstrahlung_Cutoff_Frequency (V_kmps : Float) return Float is
      V_ms : Float := V_kmps * 1000.0;                     -- m/s
      E_kin : Float := 0.5 * M_E * V_ms * V_ms;            -- Énergie cinétique en J
   begin
      return E_kin / H_PLANK;                              -- ν_max = E_kin / h
   end Bremsstrahlung_Cutoff_Frequency;

   function Get_Bremsstrahlung (Z, A : Integer; V_kmps : Float; Density_kgpm3 : Float)
                                return Bremsstrahlung_Record is
      Power     : Float := Bremsstrahlung_Power (Z, A, V_kmps, Density_kgpm3);
      Cutoff    : Float := Bremsstrahlung_Cutoff_Frequency (V_kmps);
      E_total   : Float := Power / (if Cutoff > 0.0 then Cutoff else 1.0);
      Peak      : Float := Cutoff * 0.5;  -- Pic approximatif à ν_max/2
      Eff       : Float := (if Power > 0.0 then 1.0 else 0.0); -- Simplification
   begin
      return Bremsstrahlung_Record'
        (Power_Watts          => Power,
         Cutoff_Frequency_Hz  => Cutoff,
         Total_Energy_eV      => E_total / E_CHARGE,
         Spectral_Peak_Hz     => Peak,
         Efficiency           => Eff,
         Checksum             => 9);
   end Get_Bremsstrahlung;

   -- ========================================================================
   -- 4. FONCTIONS CHERENKOV
   -- ========================================================================

   function Cherenkov_Threshold (Refractive_Index : Float) return Float is
   begin
      return C_LIGHT / Refractive_Index;
   end Cherenkov_Threshold;

   function Cherenkov_Emission_Angle (Velocity : Float; Refractive_Index : Float) return Float is
      Cos_Theta : Float := C_LIGHT / (Refractive_Index * Velocity);
   begin
      if Cos_Theta > 1.0 then
         return 0.0;  -- Pas d'émission Cherenkov
      elsif Cos_Theta < -1.0 then
         return PI;
      else
         return arccos (Cos_Theta);
      end if;
   end Cherenkov_Emission_Angle;

   function Cherenkov_Photons_Per_Meter (Velocity : Float; Refractive_Index : Float;
                                          Freq_Min, Freq_Max : Float) return Float is
      -- Formule de Frank-Tamm : dN/dx = 2πα × ∫ (1 - 1/(β²n²)) × (1/λ²) dλ
      Beta : Float := Velocity / C_LIGHT;
      Beta_n : Float := Beta * Refractive_Index;
      Factor : Float := 2.0 * PI * ALPHA_FS * (1.0 - 1.0 / (Beta_n * Beta_n));
      -- Simplification : intégrale sur 1/λ² de λ_min à λ_max
      Lambda_Min : Float := C_LIGHT / Freq_Max;
      Lambda_Max : Float := C_LIGHT / Freq_Min;
   begin
      if Beta_n <= 1.0 then
         return 0.0;  -- Pas d'émission Cherenkov
      end if;
      return Factor * (1.0 / Lambda_Min - 1.0 / Lambda_Max);
   end Cherenkov_Photons_Per_Meter;

   function Get_Cherenkov (Velocity : Float; Refractive_Index : Float;
                            Freq_Min, Freq_Max : Float) return Cherenkov_Record is
      Threshold : Float := Cherenkov_Threshold (Refractive_Index);
      Angle     : Float := Cherenkov_Emission_Angle (Velocity, Refractive_Index);
      Power     : Float := 0.0;
      Photons   : Float := Cherenkov_Photons_Per_Meter (Velocity, Refractive_Index,
                                                         Freq_Min, Freq_Max);
   begin
      if Velocity > Threshold then
         -- Puissance approximative : dE/dx ∝ (1 - 1/(β²n²)) × (1/λ²)
         Power := Photons * H_PLANK * (Freq_Min + Freq_Max) * 0.5;
      end if;
      return Cherenkov_Record'
        (Threshold_Velocity   => Threshold,
         Emission_Angle_Rad   => Angle,
         Power_Watts          => Power,
         Photons_Per_Meter    => Photons,
         Checksum             => 9);
   end Get_Cherenkov;

   -- ========================================================================
   -- 5. FONCTIONS ONDES GRAVITATIONNELLES V3
   -- ========================================================================

   function Gravitational_Wave_Amplitude (M1, M2, R_sep : Float; Frequency_Hz : Float) return Float is
      -- h = (4G/c⁴) × (M1 × M2 / R) × (π × f)²
      G_const : constant Float := 6.67430e-11;  -- N·m²/kg²
      Mu      : Float := (M1 * M2) / (M1 + M2);
      Orbital_R : Float := R_sep;
   begin
      return (4.0 * G_const / (C_LIGHT ** 4.0)) *
             (Mu / Orbital_R) *
             (2.0 * PI * Frequency_Hz) ** 2.0;
   end Gravitational_Wave_Amplitude;

   function Gravitational_Wave_Power (M1, M2, R_sep : Float; Frequency_Hz : Float) return Float is
      -- P = (32G/5c⁵) × (μ² × M² × R⁴ × ω⁶)
      G_const : constant Float := 6.67430e-11;
      M_total : Float := M1 + M2;
      Mu      : Float := (M1 * M2) / M_total;
      Omega   : Float := 2.0 * PI * Frequency_Hz;
   begin
      return (32.0 * G_const / (5.0 * (C_LIGHT ** 5.0))) *
             (Mu * Mu * M_total * (R_sep ** 4.0) * (Omega ** 6.0));
   end Gravitational_Wave_Power;

   function Get_Gravitational_Wave (M1, M2, R_sep : Float; Frequency_Hz : Float)
                                    return Gravitational_Wave is
      Amp   : Float := Gravitational_Wave_Amplitude (M1, M2, R_sep, Frequency_Hz);
      Power : Float := Gravitational_Wave_Power (M1, M2, R_sep, Frequency_Hz);
      Wav   : Float := C_LIGHT / Frequency_Hz;
   begin
      return Gravitational_Wave'
        (Frequency_Hz     => Frequency_Hz,
         Wavelength_M     => Wav,
         Amplitude_Strain => Amp,
         Power_Watts      => Power,
         Source_Mass_kg   => M1 + M2,
         Checksum         => 9);
   end Get_Gravitational_Wave;

end V3_Radiation;
