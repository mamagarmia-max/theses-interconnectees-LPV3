-- ============================================================================
-- V3_Constants.adb — Implementation V3_Constants
-- Version 11.0.0
-- ============================================================================

package body V3_Constants with
   SPARK_Mode => On
is

   function J_to_eV (Joules : Float) return Float is
   begin
      return Joules / E_CHARGE;
   end J_to_eV;

   function eV_to_J (eV : Float) return Float is
   begin
      return eV * E_CHARGE;
   end eV_to_J;

   function K_to_eV (Kelvin : Float) return Float is
   begin
      return Kelvin * K_B / E_CHARGE;
   end K_to_eV;

   function eV_to_K (eV : Float) return Float is
   begin
      return eV * E_CHARGE / K_B;
   end eV_to_K;

end V3_Constants;
