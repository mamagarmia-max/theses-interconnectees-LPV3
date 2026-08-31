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
  
