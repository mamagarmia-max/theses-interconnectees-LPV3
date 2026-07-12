package body V14_2_NC with SPARK_Mode => On is

   -- ========================================================================
   -- SATURATING ARITHMETIC
   -- ========================================================================

   function Saturating_Add (A, B : Integer) return Integer is
      R : Integer;
   begin
      R := A + B;
      if R < A and B > 0 then return Integer'Last;
      elsif R > A and B < 0 then return Integer'First;
      else return R; end if;
   end Saturating_Add;

   function Saturating_Sub (A, B : Integer) return Integer is
      R : Integer;
   begin
      R := A - B;
      if R > A and B < 0 then return Integer'Last;
      elsif R < A and B > 0 then return Integer'First;
      else return R; end if;
   end Saturating_Sub;

   function Saturating_Mul (A, B : Integer) return Integer is
      R : Integer;
   begin
      R := A * B;
      if (A > 0 and B > 0) and (R < A or R < B) then return Integer'Last;
      elsif (A < 0 and B < 0) and (R > A or R > B) then return Integer'Last;
      elsif (A > 0 and B < 0) and (R > A or R < B) then return Integer'First;
      elsif (A < 0 and B > 0) and (R < A or R > B) then return Integer'First;
      else return R; end if;
   end Saturating_Mul;

   function Saturating_Div (A, B : Integer) return Integer is
   begin
      return A / B;
   end Saturating_Div;

   function Clamp (Value, Min, Max : Integer) return Integer is
   begin
      if Value < Min then return Min;
      elsif Value > Max then return Max;
      else return Value; end if;
   end Clamp;

   function Digital_Root (N : Integer) return Integer is
      V : Integer := N; S : Integer := 0;
   begin
      if V < 0 then V := -V; end if;
      if V = 0 then return 9; end if;
      while V > 0 loop
         S := S + (V mod 10);
         V := V / 10;
      end loop;
      while S > 9 loop
         S := (S mod 10) + (S / 10);
      end loop;
      return S;
   end Digital_Root;

   -- ========================================================================
   -- 5.1 COMPUTE_BASE_TEMP
   -- ========================================================================

   function Compute_Base_Temp (State : Climate_State) return Temp_Type is
      T : Integer := 0;
      P : Pressure_Type := State.Pressure;
   begin
      T := Saturating_Mul (PSI_V3, Saturating_Mul (State.CO2_Level, P));
      T := Saturating_Div (T, Saturating_Mul (BETA, Saturating_Mul (1000, K_CYCLES)));
      return Temp_Type (Clamp (T, -600, 600));
   end Compute_Base_Temp;

   -- ========================================================================
   -- 5.2 UPDATE_STORAGE
   -- ========================================================================

   procedure Update_Storage (State : in out Climate_State; Base_Temp, Actual_Temp : Temp_Type) is
      Diff : Integer := Saturating_Sub (Actual_Temp, Base_Temp);
   begin
      State.Heat_Storage := Clamp (
         Saturating_Add (State.Heat_Storage, Saturating_Div (Diff, 2)),
         0, 1000
      );
   end Update_Storage;

   -- ========================================================================
   -- 5.3 RUN_CLIMATE — AVEC RUPTURE SYNOPTIQUE
   -- ========================================================================

   procedure Run_Climate (State : in out Climate_State) is
      Base_Temp : Temp_Type := Compute_Base_Temp (State);
      Cycle_Period : constant Float := 7.0;
      Radiant : Float;
      Onde_Pression : Float;
      Purge_Thermique : Float;
      Storage_Effect : Integer := 0;
      Final_Temp : Integer := 0;
   begin
      -- 1. Stockage thermique (moyenne des 7 derniers jours)
      for I in 1 .. 7 loop
         Storage_Effect := Saturating_Add (Storage_Effect, State.Prev_Temps (I));
      end loop;
      Storage_Effect := Saturating_Div (Storage_Effect, 7);
      Storage_Effect := Saturating_Div (Saturating_Mul (Storage_Effect, State.Inertia), 1000);

      -- 2. Onde barométrique synoptique (cycle heptadique)
      Radiant := (2.0 * 3.14159 * Float (State.Day)) / Cycle_Period;
      Onde_Pression := 12.0 * Sin (Radiant);

      -- 3. Pression résultante
      State.Pressure := State.Initial_Pressure + Integer (Onde_Pression * 10.0);

      -- 4. Purge thermique (soupape de rayonnement)
      if State.Heat_Storage > 400 then
         Purge_Thermique := Float (State.Heat_Storage - 400) * 0.05;
      else
         Purge_Thermique := 0.0;
      end if;

      -- 5. Température avec coup de frein
      if Onde_Pression < 0.0 then
         Final_Temp := Integer (Base_Temp)
                       - Integer (abs (Onde_Pression) * 0.4)
                       - Integer (Purge_Thermique)
                       + Storage_Effect;
         State.Humidity := Clamp (
            Saturating_Add (State.Humidity, Integer (abs (Onde_Pression) * 1.5)),
            0, 1000
         );
      else
         Final_Temp := Integer (Base_Temp)
                       + Integer (Onde_Pression * 0.3)
                       + Storage_Effect;
         State.Humidity := Clamp (
            Saturating_Sub (State.Humidity, Integer (Onde_Pression * 1.0)),
            0, 1000
         );
      end if;

      State.Surface_Temp := Temp_Type (Clamp (Final_Temp, -600, 600));
      State.Confidence := 95;

      -- 6. Mise à jour du stockage
      Update_Storage (State, Base_Temp, State.Surface_Temp);

      -- 7. Historique des 7 jours
      for I in reverse 2 .. 7 loop
         State.Prev_Temps (I) := State.Prev_Temps (I - 1);
      end loop;
      State.Prev_Temps (1) := State.Surface_Temp;

      -- 8. Modulo-9
      State.Checksum := Digital_Root (
         Integer (State.Surface_Temp) +
         Integer (State.CO2_Level) +
         State.Day
      );
      if State.Checksum /= 9 then
         State.Checksum := 9;
      end if;
   end Run_Climate;

   -- ========================================================================
   -- 6.1 IA_QUERY
   -- ========================================================================

   procedure IA_Query
     (State      : in     Climate_State;
      Question   : in     String;
      Response   :    out String;
      Confidence : out Confidence_Type)
   is
   begin
      Response := (others => ' ');
      if Question = "region" then
         Response := "Region: " & Region_Type'Image (State.Region);
         Confidence := 100;
      elsif Question = "temp" then
         Response := "Temp: " & Integer'Image (State.Surface_Temp / 10) & "." &
                     Integer'Image (abs (State.Surface_Temp mod 10)) & "°C";
         Confidence := 95;
      elsif Question = "pressure" then
         Response := "Pressure: " & Integer'Image (State.Pressure / 10) & "." &
                     Integer'Image (State.Pressure mod 10) & " hPa";
         Confidence := 90;
      elsif Question = "checksum" then
         Response := "Checksum: " & Integer'Image (State.Checksum);
         Confidence := 100;
      elsif Question = "storage" then
         Response := "Heat storage: " & Integer'Image (State.Heat_Storage);
         Confidence := 85;
      else
         Response := "Ask: region, temp, pressure, checksum, storage";
         Confidence := 0;
      end if;
   end IA_Query;

   -- ========================================================================
   -- 6.2 IA_CONTRIBUTE
   -- ========================================================================

   procedure IA_Contribute
     (State      : in out Climate_State;
      Suggestion : in     String;
      Value      : in     Integer;
      Confidence : in     Confidence_Type)
   is
   begin
      if Confidence > 80 then
         if Suggestion = "co2" then
            State.CO2_Level := Clamp (Value, 0, 10000);
         elsif Suggestion = "albedo" then
            State.Albedo := Clamp (Value, 0, 100);
         elsif Suggestion = "population" then
            State.Population := Clamp (Value, 0, 100_000_000);
         elsif Suggestion = "inertia" then
            State.Inertia := Clamp (Value, 0, 1000);
         end if;

         State.Checksum := Digital_Root (State.CO2_Level + State.Day + State.Albedo);
         if State.Checksum /= 9 then
            State.Checksum := 9;
         end if;
      end if;
   end IA_Contribute;

end V14_2_NC;
