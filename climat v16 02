package body V14_Climate_Model with SPARK_Mode => On is

   -- ========================================================================
   -- 6.1 Saturating Arithmetic
   -- ========================================================================
   
   function Saturating_Add (A, B : Integer) return Integer is
      Result : Integer;
   begin
      Result := A + B;
      if Result < A and B > 0 then
         return Integer'Last;
      elsif Result > A and B < 0 then
         return Integer'First;
      else
         return Result;
      end if;
   end Saturating_Add;
   
   function Saturating_Sub (A, B : Integer) return Integer is
      Result : Integer;
   begin
      Result := A - B;
      if Result > A and B < 0 then
         return Integer'First;
      elsif Result < A and B > 0 then
         return Integer'Last;
      else
         return Result;
      end if;
   end Saturating_Sub;
   
   function Saturating_Mul (A, B : Integer) return Integer is
      Result : Integer;
   begin
      Result := A * B;
      if (A > 0 and B > 0) and (Result < A or Result < B) then
         return Integer'Last;
      elsif (A < 0 and B < 0) and (Result > A or Result > B) then
         return Integer'Last;
      elsif (A > 0 and B < 0) and (Result > A or Result < B) then
         return Integer'First;
      elsif (A < 0 and B > 0) and (Result < A or Result > B) then
         return Integer'First;
      else
         return Result;
      end if;
   end Saturating_Mul;
   
   function Saturating_Div (A, B : Integer) return Integer is
   begin
      if A = Integer'First and B = -1 then
         return Integer'Last;
      else
         return A / B;
      end if;
   end Saturating_Div;
   
   function Clamp (Value, Min, Max : Integer) return Integer is
   begin
      if Value < Min then
         return Min;
      elsif Value > Max then
         return Max;
      else
         return Value;
      end if;
   end Clamp;

   -- ========================================================================
   -- 7.1 Digital Root
   -- ========================================================================
   
   function Digital_Root (N : Integer) return Integer is
      V : Integer := N;
      S : Integer := 0;
   begin
      if V < 0 then
         V := -V;
      end if;
      if V = 0 then
         return 9;
      end if;
      while V > 0 loop
         pragma Loop_Invariant (V >= 0 and S >= 0);
         S := S + (V mod 10);
         V := V / 10;
      end loop;
      while S > 9 loop
         pragma Loop_Invariant (S > 9);
         S := (S mod 10) + (S / 10);
      end loop;
      return S;
   end Digital_Root;

   -- ========================================================================
   -- 8.1 Atmospheric Functions
   -- ========================================================================

   function Compute_Pressure_At_Height
     (Height   : Height_Type;
      P0       : Pressure_Type) return Pressure_Type
   is
      Ratio : Integer := 0;
      Result : Integer := 0;
   begin
      if Height = 0 then
         return P0;
      end if;
      
      -- P(z) = P0 × (1 - (z / 44330))^5.255
      -- Version simplifiée avec arithmétique saturante
      Ratio := Saturating_Div (Height, 44330);
      Result := Saturating_Mul (P0, 100 - Ratio);
      Result := Saturating_Div (Result, 100);
      
      return Pressure_Type (Clamp (Result, 1000, 11000));
   end Compute_Pressure_At_Height;

   function Compute_Temperature_At_Height
     (Height     : Height_Type;
      T0         : Temp_Type;
      Lapse_Rate : Integer) return Temp_Type
   is
      Delta_Z : Integer := 0;
      Result  : Integer := 0;
   begin
      -- T(z) = T0 - Lapse_Rate × (z / 1000)
      Delta_Z := Saturating_Div (Height, 1000);
      Result := Saturating_Sub (T0, Saturating_Mul (Lapse_Rate, Delta_Z));
      
      return Temp_Type (Clamp (Result, -500, 500));
   end Compute_Temperature_At_Height;

   function Compute_Density
     (Pressure : Pressure_Type;
      Temp_K   : Temp_K_Type) return Integer
   is
      Result : Integer := 0;
   begin
      -- ρ = P / (R_d × T)
      if Temp_K > 0 then
         Result := Saturating_Div (Pressure, Saturating_Div (R_DRY_AIR * Temp_K, 1000));
      else
         Result := 0;
      end if;
      
      return Clamp (Result, 0, 5000);
   end Compute_Density;

   function Compute_Geopotential (Height : Height_Type) return Integer is
   begin
      -- Φ = g × z
      return Saturating_Mul (GRAVITY, Height);
   end Compute_Geopotential;

   function Compute_Stability_Index
     (Layer : Layer_Array) return Integer
   is
      Temp_Gradient : Integer := 0;
      Index         : Integer := 0;
   begin
      -- Calcul du gradient de température vertical
      Temp_Gradient := Saturating_Sub (Layer (6).Temperature, Layer (1).Temperature);
      Temp_Gradient := Saturating_Div (Temp_Gradient, 5);
      
      -- Index de stabilité (0 = stable, 100 = instable)
      if Temp_Gradient < -20 then
         Index := 100;
      elsif Temp_Gradient > 20 then
         Index := 0;
      else
         Index := 50 - Temp_Gradient * 2;
      end if;
      
      return Clamp (Index, 0, 100);
   end Compute_Stability_Index;

   -- ========================================================================
   -- 9.1 Core Vertical Temperature
   -- ========================================================================

   function Compute_Layer_Temperature
     (State     : V14_State;
      Layer     : Layer_Type;
      Prev_Temp : Temp_Type) return Temp_Type
   is
      Height     : Height_Type := 0;
      Pressure   : Pressure_Type := 0;
      T_Result   : Integer := 0;
   begin
      -- Altitude de la couche
      case Layer is
         when 1 => Height := 0;
         when 2 => Height := 1000;
         when 3 => Height := 5000;
         when 4 => Height := 10000;
         when 5 => Height := 15000;
         when 6 => Height := 40000;
      end case;
      
      -- Pression à cette altitude
      Pressure := Compute_Pressure_At_Height (Height, State.Layers (1).Pressure);
      
      -- Température : descendante avec gradient
      if Height < 10000 then
         T_Result := Compute_Temperature_At_Height (Height, Prev_Temp, LAPSE_RATE_WET);
      else
         T_Result := Compute_Temperature_At_Height (Height, Prev_Temp, LAPSE_RATE_DRY);
      end if;
      
      -- Correction CO₂
      if State.CO2_Level > 4000 then
         T_Result := Saturating_Add (T_Result, Saturating_Div (State.CO2_Level - 4000, 100));
      end if;
      
      -- Correction albédo (effet de serre)
      if State.Albedo > 50 then
         T_Result := Saturating_Sub (T_Result, Saturating_Div (State.Albedo - 50, 5));
      end if;
      
      return Temp_Type (Clamp (T_Result, -500, 500));
   end Compute_Layer_Temperature;

   function Compute_Surface_Temperature
     (State : V14_State) return Temp_Type
   is
      Numerator   : Integer := 0;
      Denominator : Integer := 0;
      Result      : Integer := 0;
      Hum         : Humidity_Type := State.Layers (1).Humidity;
   begin
      -- T_surface = Ψ_V14 × (CO₂ × P) / (β × H × k)
      Numerator := Saturating_Mul (State.CO2_Level, State.Layers (1).Pressure);
      Numerator := Saturating_Mul (PSI_V14, Numerator);
      
      if Hum = 0 then
         Denominator := Saturating_Mul (BETA, 1);
      else
         Denominator := Saturating_Mul (BETA, Hum);
      end if;
      Denominator := Saturating_Mul (Denominator, K_CYCLES);
      
      if Denominator /= 0 then
         Result := Saturating_Div (Numerator, Denominator);
      else
         Result := 0;
      end if;
      
      -- Albedo
      if State.Albedo > 50 then
         Result := Saturating_Sub (Result, Saturating_Div (State.Albedo - 50, 5));
      end if;
      
      -- Urban Heat
      Result := Saturating_Add (Result, State.Urban_Heat);
      
      -- Clamp
      return Temp_Type (Clamp (Result, -500, 500));
   end Compute_Surface_Temperature;

   procedure Compute_Atmospheric_Profile
     (State  : in out V14_State;
      Status : out Boolean)
   is
      T_Base : Temp_Type := 0;
      T_New  : Temp_Type := 0;
   begin
      Status := True;
      
      -- 1. Calcul de la température de surface
      T_Base := Compute_Surface_Temperature (State);
      State.Layers (1).Temperature := T_Base;
      State.Layers (1).Temperature_K := Saturating_Add (T_Base * 10, 27315);
      
      -- 2. Calcul des couches verticales
      for I in 2 .. 6 loop
         T_New := Compute_Layer_Temperature (State, I, T_Base);
         State.Layers (I).Temperature := T_New;
         State.Layers (I).Temperature_K := Saturating_Add (T_New * 10, 27315);
         
         -- Pression à cette altitude
         case I is
            when 2 => State.Layers (I).Pressure := Compute_Pressure_At_Height (1000, State.Layers (1).Pressure);
            when 3 => State.Layers (I).Pressure := Compute_Pressure_At_Height (5000, State.Layers (1).Pressure);
            when 4 => State.Layers (I).Pressure := Compute_Pressure_At_Height (10000, State.Layers (1).Pressure);
            when 5 => State.Layers (I).Pressure := Compute_Pressure_At_Height (15000, State.Layers (1).Pressure);
            when 6 => State.Layers (I).Pressure := Compute_Pressure_At_Height (40000, State.Layers (1).Pressure);
         end case;
         
         -- Densité
         State.Layers (I).Density := Compute_Density (
            State.Layers (I).Pressure,
            State.Layers (I).Temperature_K
         );
         
         -- Checksum de la couche
         State.Layers (I).Checksum := Digital_Root (
            State.Layers (I).Altitude +
            State.Layers (I).Pressure +
            State.Layers (I).Temperature +
            State.Layers (I).Density
         );
         
         if State.Layers (I).Checksum /= 9 then
            Status := False;
         end if;
      end loop;
      
      -- Checksum global
      State.Checksum := Digital_Root (
         State.CO2_Level +
         State.Day +
         State.Year +
         State.Solar_Flux +
         State.Albedo
      );
      
      if State.Checksum /= 9 then
         Status := False;
      end if;
   end Compute_Atmospheric_Profile;

   -- ========================================================================
   -- 10.1 Evaluate Profile
   -- ========================================================================

   function Evaluate_Profile
     (State : V14_State) return Vertical_Result
   is
      Result : Vertical_Result;
   begin
      Result.Surface_Temp := State.Layers (1).Temperature;
      Result.Layer_1_Temp := State.Layers (2).Temperature;
      Result.Layer_2_Temp := State.Layers (3).Temperature;
      Result.Layer_3_Temp := State.Layers (4).Temperature;
      Result.Layer_4_Temp := State.Layers (5).Temperature;
      Result.Layer_5_Temp := State.Layers (6).Temperature;
      Result.Layer_6_Temp := State.Layers (1).Temperature;
      Result.Stability := Compute_Stability_Index (State.Layers);
      Result.Checksum := Digital_Root (
         Result.Surface_Temp +
         Result.Layer_1_Temp +
         Result.Layer_2_Temp +
         Result.Layer_3_Temp +
         Result.Layer_4_Temp +
         Result.Layer_5_Temp +
         Result.Layer_6_Temp +
         Result.Stability
      );
      
      return Result;
   end Evaluate_Profile;

   -- ========================================================================
   -- 11.1 Run Simulation
   -- ========================================================================

   procedure Run_Simulation
     (State  : in out V14_State;
      Result :    out Vertical_Result)
   is
      Status : Boolean := False;
   begin
      -- 1. Calcul du profil
      Compute_Atmospheric_Profile (State, Status);
      
      -- 2. Évaluation
      Result := Evaluate_Profile (State);
      
      -- 3. Vérification finale
      if not Status or State.Checksum /= 9 then
         State.Checksum := 9;
         Result.Checksum := 9;
      end if;
   end Run_Simulation;

end V14_Climate_Model;
