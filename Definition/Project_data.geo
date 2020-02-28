// Gmsh project created on Mon Feb 24 13:28:48 2020
// SetFactory("OpenCASCADE");

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

//UI Path            :

PathGeometricParameters  = "Input/010Geometric parameters/" ;
PathMaterialsParameters  = "Input/030Materials parameters/" ;
PathElectricalParameters = "Input/020Electrical parameters/";
PathMeshParameters       = "Input/040Mesh parameters/"      ;

//UI parameters      :
	//We used annealed copper. For fresh copper replace 17.2 with 16.8 :) 

DefineConstant[ Rext_UI           = { 100 , Name StrCat[PathGeometricParameters,"005External radius of the hollow tube (in mm)"], Highlight "LightBlue1"} ];    
DefineConstant[ Rint_UI           = { 60 , Name StrCat[PathGeometricParameters,"010Internal radius of the hollow tube (in mm)"],Highlight "LightBlue1"} ]  ;
DefineConstant[ freq              = { 50 , Name StrCat[PathElectricalParameters,"020Operating frequency (in Hz)"],Highlight "Orange"} ]                    ;
DefineConstant[ C_rho_UI          = { 17.2 , Name StrCat[PathMaterialsParameters ,"010Copper resistivity (in nOhm)"],Highlight "Pink"} ]                   ;
DefineConstant[ C_mu              = { 0.999994 , Name StrCat[PathMaterialsParameters ,"020Relative permeability of Copper"],Highlight "Pink"} ]            ;
DefineConstant[ Voltage_supply_UI = { 550 , Name StrCat[PathElectricalParameters,"010Supply voltage (in kV)"],Highlight "Orange"} ]                        ;
DefineConstant[ Breakdown_vol_UI  = { 3 , Name StrCat[PathElectricalParameters,"030Electrical breakdown (in MV per m)"],Highlight "Orange"} ]              ;
DefineConstant[ Flag_Insulation   = { 0, Choices{0,1}, Name StrCat[PathMaterialsParameters, "030Add insulation layer?" ] } ]                               ;
DefineConstant[ R_airbox          = { 5, Name StrCat[PathGeometricParameters, "The minimum airbox radius (in m)" ] } ]                                     ;
DefineConstant[ Num_litz          = { 1, Min 1, Max 10, Step 1, Name StrCat[PathGeometricParameters, "Number of small conductors" ] } ]                                           ;
DefineConstant[ d_cond          = { 1, Name StrCat[PathGeometricParameters, "Distance bewteen the small conductors surface (in mm)" ] } ]                  ;
//Ajouter résistance de la charge 

If (Flag_Insulation )
 	DefineConstant[ Insulation_UI = {1000, Name StrCat[PathMaterialsParameters, "040Insulation thickness in (µm)"], Highlight "Pink"  } ]          ;
	DefineConstant[ Ins_epsr      = {3.5, Name StrCat[PathMaterialsParameters, "050Relative permittivity of the insulation"], Highlight "Pink"  } ];
	Insulation     = Insulation_UI * 1e-6 ;
	lc_Insulation  = Insulation / 5       ;
EndIf 

//Real parameters    
Rext    = Rext_UI * mili          ;
Rint    = Rint_UI * mili          ;
Rint 	= Rext 					  ;
mu      = mu_0 * C_mu             ;
C_rho   = C_rho_UI * nano         ;
Break_V = Breakdown_vol_UI * Mega ; 					  //interspire? 
Voltage = Voltage_supply_UI * kilo;
d_cond  = d_cond * mili		  	  ;						  // Distance betwen the surface of two neighbouring small conductors

//Useful computations
Delta   = Sqrt[C_rho/(Pi*mu*freq)] 						; // Skin depth = the ideal Litz wires radius
Surf    = Pi*(Rext*Rext-((Rext-Delta)*(Rext-Delta))) 	; // The hollow conductor's effective surface (m^2)
//Resis   = C_rho * pul / Surf       						; // Resistance of a 1meter length hollow conductor
//I_total = Voltage / Resis         						; // The total current in the hollow conductor

//Parameters of the 2D Litz wires:

//S_litz   = Pi * Delta * Delta   						;
//R_small  = C_rho * pul / S_litz 						; //per unit length **ADD LOAD'S RESISTANCE!!
//I_litz   = Voltage / R_small    						; 
// Num_litz = I_total / I_litz     						;
Eff_surf_new = Surf/(Num_litz)							; // Effective surface of one small conductor (assume Rc>delta ==> not true if nb_cond>21)
Rc = ((Eff_surf_new)+(Pi*Delta*Delta))/(2*Pi*Delta)			; // Small conductors radius

//Fogot the airbox parameters:
//THE USE OF THE BREAKDOWN VOLTAGE??? Paschen law or what? 

//Physical tags
//Airbox
SKIN_AIRBOX      = 500000;
SURF_AIRBOX      = 600000;
//Conductors
SKIN_CONDUCTORS  = 700000;
//Insulations
SURF_INSULATIONS = 900000;

