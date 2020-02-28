// Gmsh project created on Mon Feb 24 13:28:48 2020

//KMS defined

mili  = 1.e-3 ;
micro = 1.e-6 ;
nano  = 1.e-9 ;
kilo  = 1.e+3 ;
Mega  = 1.e+6 ; 
pul   = 1.    ; //per unit length;

//Material parameters:

mu_0 = 4*Pi*1e-7        ;
eps0 = (1/(36*Pi))*1e-9 ; 

//UI Path            

PathGeometricParameters  = "Input/010Geometric parameters/" ;
PathMaterialsParameters  = "Input/030Materials parameters/" ;
PathElectricalParameters = "Input/020Electrical parameters/";
PathMeshParameters       = "Input/040Mesh parameters/"      ;

//UI parameters      
	//We used annealed copper. For fresh copper replace 17.2 with 16.8 :) 

Rext_UI           = DefineNumber[100 , Name StrCat[PathGeometricParameters,"005External radius of the hollow tube (in mm)"], Highlight "LightBlue1"];    
Rint_UI           = DefineNumber[60 , Name StrCat[PathGeometricParameters,"010Internal radius of the hollow tube (in mm)"],Highlight "LightBlue1"]  ;
freq              = DefineNumber[50 , Name StrCat[PathElectricalParameters,"020Operating frequency (in Hz)"],Highlight "Orange"]                    ;
C_rho_UI          = DefineNumber[17.2 , Name StrCat[PathMaterialsParameters ,"010Copper resistivity (in nOhm)"],Highlight "Pink"]                   ;
C_mu              = DefineNumber[0.999994 , Name StrCat[PathMaterialsParameters ,"020Relative permeability of Copper"],Highlight "Pink"]            ;
Voltage_supply_UI = DefineNumber[550 , Min 550,Max 5000, Step 1e3, Name StrCat[PathElectricalParameters,"010Supply voltage (in kV)"],Highlight "Orange"] ;
Breakdown_vol_UI  = DefineNumber[3 , Name StrCat[PathElectricalParameters,"030Electrical breakdown (in MV per m)"],Highlight "Orange" ]             ;
Flag_Insulation   = DefineNumber[0, Choices{0,1}, Name StrCat[PathMaterialsParameters, "030Add insulation layer?"  ]]                                ;
R_airbox          = DefineNumber[5, Name StrCat[PathGeometricParameters, "The minimum airbox radius (in m)" ]]                                       ; 
Num_litz          = DefineNumber[1, Min 1 , Max 21, Name StrCat[PathGeometricParameters, "Number of small conductors" ]]                             ;
d_cond            = DefineNumber[1, Name StrCat[PathGeometricParameters, "Distance bewteen the small conductors surface (in mm)" ] ]               ;

If (Flag_Insulation )
 	Insulation_UI  = DefineNumber[1000, Name StrCat[PathMaterialsParameters, "040Insulation thickness in (µm)"], Highlight "Pink"];
	Ins_epsr       = DefineNumber[3.5, Name StrCat[PathMaterialsParameters, "050Relative permittivity of the insulation"], Highlight "Pink"]  ;
	Insulation     = Insulation_UI * 1e-6 ;
	lc_Insulation  = Insulation / 5       ;
EndIf 

//Real parameters    
Rext    = Rext_UI * mili          ;
Rint    = Rint_UI * mili          ;
Rint 	= Rext 					  ;
mu      = mu_0 * C_mu             ;
C_rho   = C_rho_UI * nano         ;
Break_V = Breakdown_vol_UI * Mega ; 					  
Voltage = Voltage_supply_UI * kilo;
d_cond  = d_cond * mili		  	  ;				       // Distance betwen the surface of two neighbouring small conductors

//Useful computations
Delta   = Sqrt[C_rho/(Pi*mu*freq)] 					; // Skin depth = the ideal Litz wires radius
Surf    = Pi*(Rext*Rext-((Rext-Delta)*(Rext-Delta))); // The hollow conductor's effective surface (m^2)
Eff_surf_new = Surf/(Num_litz)						; // Effective surface of one small conductor (assume Rc>delta ==> not true if nb_cond>21)
Rc = ((Eff_surf_new)+(Pi*Delta*Delta))/(2*Pi*Delta)	; // Small conductors radius

//Physical tags
SKIN_AIRBOX      = 500000;
SURF_AIRBOX      = 600000;
SKIN_CONDUCTORS  = 700000;
SURF_INSULATIONS = 900000;

//Mesh sizes are defined in the data.geo.
